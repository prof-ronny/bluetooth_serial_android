package prof.ronny.bluetooth_serial_android

import android.Manifest
import android.app.Activity
import android.bluetooth.BluetoothAdapter
import android.bluetooth.BluetoothDevice
import android.bluetooth.BluetoothManager
import android.bluetooth.BluetoothSocket
import android.content.Context
import android.content.IntentFilter
import android.content.pm.PackageManager
import androidx.annotation.NonNull
import androidx.core.app.ActivityCompat
import androidx.core.content.ContextCompat
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.embedding.engine.plugins.activity.ActivityAware
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import java.io.IOException
import java.io.InputStream
import java.io.OutputStream
import java.util.*
import kotlin.concurrent.thread

/** Plugin principal Bluetooth Serial Android **/
class BluetoothSerialAndroidPlugin :
    FlutterPlugin,
    MethodChannel.MethodCallHandler,
    ActivityAware {

    private lateinit var channel: MethodChannel
    private var context: Context? = null
    private var activity: Activity? = null
    private var adapter: BluetoothAdapter? = null
    private var socket: BluetoothSocket? = null
    private var input: InputStream? = null
    private var output: OutputStream? = null

    override fun onAttachedToEngine(@NonNull binding: FlutterPlugin.FlutterPluginBinding) {
        channel = MethodChannel(binding.binaryMessenger, "bluetooth_serial_android")
        channel.setMethodCallHandler(this)
        context = binding.applicationContext
        adapter = (context?.getSystemService(Context.BLUETOOTH_SERVICE) as BluetoothManager).adapter
    }

    // ========================================================
    //                  MÉTODOS FLUTTER
    // ========================================================
    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "ensurePermissions" -> ensurePermissions(result)
            "getPairedDevices" -> getPairedDevices(result)
            "scanDevices" -> scanDevices(result)
            "connect" -> connect(call.argument<String>("address"), result)
            "disconnect" -> {
                disconnect()
                result.success(true)
            }
            "write" -> {
                val message = call.argument<String>("message") ?: ""
                write(message, result)
            }
            "read" -> read(result)
            else -> result.notImplemented()
        }
    }

    // ========================================================
    //                  PERMISSÕES
    // ========================================================
    private fun ensurePermissions(result: MethodChannel.Result) {
        val act = activity
        val ctx = context
        if (act == null || ctx == null) {
            result.error("NO_ACTIVITY", "Activity não disponível", null)
            return
        }

        val requiredPermissions = mutableListOf(
            Manifest.permission.BLUETOOTH_CONNECT,
            Manifest.permission.BLUETOOTH_SCAN,
            Manifest.permission.ACCESS_FINE_LOCATION
        )

        val missingPermissions = requiredPermissions.filter {
            ContextCompat.checkSelfPermission(ctx, it) != PackageManager.PERMISSION_GRANTED
        }

        if (missingPermissions.isEmpty()) {
            result.success(true)
            return
        }

        ActivityCompat.requestPermissions(act, missingPermissions.toTypedArray(), 1001)
        result.success(false)
    }

    // ========================================================
    //                  LISTAR DISPOSITIVOS PAREADOS
    // ========================================================
    private fun getPairedDevices(result: MethodChannel.Result) {
        if (adapter == null) {
            result.error("NO_ADAPTER", "Bluetooth não suportado", null)
            return
        }

        val devices = adapter!!.bondedDevices.map {
            mapOf("name" to (it.name ?: "Desconhecido"), "address" to it.address)
        }
        result.success(devices)
    }

    // ========================================================
    //                  BUSCAR DISPOSITIVOS (SCAN)
    // ========================================================
    private fun scanDevices(result: MethodChannel.Result) {
        val ctx = context ?: return result.error("NO_CONTEXT", "Contexto ausente", null)
        val act = activity ?: return result.error("NO_ACTIVITY", "Activity ausente", null)
        val adapter = adapter ?: return result.error("NO_ADAPTER", "Bluetooth não suportado", null)

        val hasScan = ContextCompat.checkSelfPermission(ctx, Manifest.permission.BLUETOOTH_SCAN) == PackageManager.PERMISSION_GRANTED
        val hasLoc = ContextCompat.checkSelfPermission(ctx, Manifest.permission.ACCESS_FINE_LOCATION) == PackageManager.PERMISSION_GRANTED

        if (!hasScan || !hasLoc) {
            ActivityCompat.requestPermissions(act, arrayOf(
                Manifest.permission.BLUETOOTH_SCAN,
                Manifest.permission.ACCESS_FINE_LOCATION
            ), 1001)
            result.error("NO_PERMISSION", "Permissões não concedidas", null)
            return
        }

        val devicesFound = mutableListOf<Map<String, String>>()

        val receiver = object : android.content.BroadcastReceiver() {
            override fun onReceive(context: Context?, intent: android.content.Intent?) {
                val action = intent?.action
                if (BluetoothDevice.ACTION_FOUND == action) {
                    val device: BluetoothDevice? =
                        intent.getParcelableExtra(BluetoothDevice.EXTRA_DEVICE, BluetoothDevice::class.java)
                    if (device != null) {
                        val map = mapOf(
                            "name" to (device.name ?: "Desconhecido"),
                            "address" to device.address
                        )
                        if (!devicesFound.any { it["address"] == device.address }) {
                            devicesFound.add(map)
                            channel.invokeMethod("onDeviceFound", map)
                        }
                    }
                } else if (BluetoothAdapter.ACTION_DISCOVERY_FINISHED == action) {
                    ctx.unregisterReceiver(this)
                    result.success(devicesFound)
                }
            }
        }

        val filter = IntentFilter()
        filter.addAction(BluetoothDevice.ACTION_FOUND)
        filter.addAction(BluetoothAdapter.ACTION_DISCOVERY_FINISHED)
        ctx.registerReceiver(receiver, filter)

        if (adapter.isDiscovering) adapter.cancelDiscovery()
        val started = adapter.startDiscovery()
        if (!started) {
            ctx.unregisterReceiver(receiver)
            result.error("DISCOVERY_FAILED", "Não foi possível iniciar o scan", null)
        }
    }

    // ========================================================
    //                  CONECTAR A UM DISPOSITIVO
    // ========================================================
    private fun connect(address: String?, result: MethodChannel.Result) {
        if (address == null) {
            result.error("INVALID_ADDRESS", "Endereço Bluetooth inválido", null)
            return
        }

        thread {
            try {
                val device: BluetoothDevice? = adapter?.getRemoteDevice(address)
                val uuid = UUID.fromString("00001101-0000-1000-8000-00805F9B34FB") // UUID padrão SPP
                socket = device?.createRfcommSocketToServiceRecord(uuid)
                adapter?.cancelDiscovery()
                socket?.connect()
                input = socket?.inputStream
                output = socket?.outputStream
                activity?.runOnUiThread { result.success(true) }
            } catch (e: IOException) {
                activity?.runOnUiThread { result.error("CONNECTION_FAILED", e.message, null) }
            }
        }
    }

    // ========================================================
    //                  DESCONECTAR
    // ========================================================
    private fun disconnect() {
        try {
            input?.close()
            output?.close()
            socket?.close()
        } catch (e: IOException) {
            e.printStackTrace()
        }
    }

    // ========================================================
    //                  ESCRITA (ASSÍNCRONA)
    // ========================================================
    private fun write(message: String, result: MethodChannel.Result) {
        thread {
            try {
                output?.write(message.toByteArray())
                activity?.runOnUiThread {
                    result.success(true)
                }
            } catch (e: IOException) {
                activity?.runOnUiThread {
                    result.error("WRITE_ERROR", e.message, null)
                }
            }
        }
    }

    // ========================================================
    //                  LEITURA (ASSÍNCRONA)
    // ========================================================
    private fun read(result: MethodChannel.Result) {
        thread {
            try {
                val buffer = ByteArray(1024)
                val bytes = input?.read(buffer) ?: -1
                val data = if (bytes > 0) String(buffer, 0, bytes) else null
                activity?.runOnUiThread {
                    result.success(data)
                }
            } catch (e: IOException) {
                activity?.runOnUiThread {
                    result.error("READ_ERROR", e.message, null)
                }
            }
        }
    }

    // ========================================================
    //                  GERENCIAMENTO DE ACTIVITY
    // ========================================================
    override fun onAttachedToActivity(binding: ActivityPluginBinding) {
        activity = binding.activity
    }

    override fun onDetachedFromActivityForConfigChanges() {
        activity = null
    }

    override fun onReattachedToActivityForConfigChanges(binding: ActivityPluginBinding) {
        activity = binding.activity
    }

    override fun onDetachedFromActivity() {
        activity = null
    }

    override fun onDetachedFromEngine(@NonNull binding: FlutterPlugin.FlutterPluginBinding) {
        channel.setMethodCallHandler(null)
    }
}

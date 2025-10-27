import 'package:plugin_platform_interface/plugin_platform_interface.dart';
import 'bluetooth_serial_android_method_channel.dart';

abstract class BluetoothSerialPlatform extends PlatformInterface {
  BluetoothSerialPlatform() : super(token: _token);

  static final Object _token = Object();

  static BluetoothSerialPlatform _instance = MethodChannelBluetoothSerial();

  /// Implementação padrão (Android)
  static BluetoothSerialPlatform get instance => _instance;

  static set instance(BluetoothSerialPlatform instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  /// Métodos que toda plataforma deve implementar
  Future<List<Map<String, String>>> getPairedDevices();
  Future<List<Map<String, String>>> scanDevices();
  Future<bool> connect(String address);
  Future<void> disconnect();
  Future<void> write(String message);
  Future<String?> read();
  Future<bool> ensurePermissions();
}

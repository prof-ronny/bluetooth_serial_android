import 'bluetooth_serial_android_platform_interface.dart';

class FlutterBluetoothSerial {
  /// Lista dispositivos já pareados
  static Future<List<Map<String, String>>> getPairedDevices() {
    return BluetoothSerialPlatform.instance.getPairedDevices();
  }

  /// Escaneia dispositivos próximos
  static Future<List<Map<String, String>>> scanDevices() {
    return BluetoothSerialPlatform.instance.scanDevices();
  }

  /// Conecta a um dispositivo via endereço MAC
  static Future<bool> connect(String address) {
    return BluetoothSerialPlatform.instance.connect(address);
  }

  /// Envia texto ou comando serial
  static Future<void> write(String message) {
    return BluetoothSerialPlatform.instance.write(message);
  }

  /// Lê dados disponíveis na conexão
  static Future<String?> read() {
    return BluetoothSerialPlatform.instance.read();
  }

  /// Fecha a conexão
  static Future<void> disconnect() {
    return BluetoothSerialPlatform.instance.disconnect();
  }

  static Future<bool> ensurePermissions() async {
    final result = await BluetoothSerialPlatform.instance.ensurePermissions();
    return result == true;
  }
}

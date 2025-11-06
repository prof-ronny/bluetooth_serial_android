import 'bluetooth_serial_android_platform_interface.dart';

class FlutterBluetoothSerial {
  static Future<bool> ensurePermissions() {
    return BluetoothSerialPlatform.instance.ensurePermissions();
  }

  static Future<List<Map<String, String>>> getPairedDevices() {
    return BluetoothSerialPlatform.instance.getPairedDevices();
  }

  static Future<List<Map<String, String>>> scanDevices() {
    return BluetoothSerialPlatform.instance.scanDevices();
  }

  static Future<bool> connect(
    String address, {
    String uuid = "00001101-0000-1000-8000-00805F9B34FB",
    int timeoutMs = 200,
  }) {
    return BluetoothSerialPlatform.instance.connect(
      address,
      uuid: uuid,
      timeoutMs: timeoutMs,
    );
  }

  static Future<void> disconnect() {
    return BluetoothSerialPlatform.instance.disconnect();
  }

  static Future<void> write(String message) {
    return BluetoothSerialPlatform.instance.write(message);
  }

  static Future<String?> read() {
    return BluetoothSerialPlatform.instance.read();
  }

  static Future<String?> readLine([String delimiter = "\n"]) {
    return BluetoothSerialPlatform.instance.readLine(delimiter);
  }
}

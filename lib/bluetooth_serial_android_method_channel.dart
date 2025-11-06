import 'package:flutter/services.dart';
import 'bluetooth_serial_android_platform_interface.dart';

class MethodChannelBluetoothSerial extends BluetoothSerialPlatform {
  static const _channel = MethodChannel('bluetooth_serial_android');

  @override
  Future<bool> ensurePermissions() async {
    final result = await _channel.invokeMethod('ensurePermissions');
    return result == true;
  }

  @override
  Future<List<Map<String, String>>> getPairedDevices() async {
    final result = await _channel.invokeMethod('getPairedDevices');
    return List<Map<String, String>>.from(
      (result as List).map((e) => Map<String, String>.from(e)),
    );
  }

  @override
  Future<List<Map<String, String>>> scanDevices() async {
    final result = await _channel.invokeMethod('scanDevices');
    return List<Map<String, String>>.from(
      (result as List).map((e) => Map<String, String>.from(e)),
    );
  }

  @override
  Future<bool> connect(
    String address, {
    String uuid = "00001101-0000-1000-8000-00805F9B34FB",
    int timeoutMs = 200,
  }) async {
    final result = await _channel.invokeMethod('connect', {
      'address': address,
      'uuid': uuid,
      'timeoutMs': timeoutMs,
    });
    return result == true;
  }

  @override
  Future<void> disconnect() async {
    await _channel.invokeMethod('disconnect');
  }

  @override
  Future<void> write(String message) async {
    await _channel.invokeMethod('write', {'message': message});
  }

  @override
  Future<String?> read() async {
    return await _channel.invokeMethod('read');
  }

  @override
  Future<String?> readLine([String delimiter = "\n"]) async {
    return await _channel.invokeMethod('readLine', {'delimiter': delimiter});
  }
}

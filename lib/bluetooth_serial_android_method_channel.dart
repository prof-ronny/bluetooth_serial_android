import 'package:flutter/services.dart';
import 'bluetooth_serial_android_platform_interface.dart';

class MethodChannelBluetoothSerial extends BluetoothSerialPlatform {
  static const _channel = MethodChannel('bluetooth_serial_android');

  @override
  Future<List<Map<String, String>>> getPairedDevices() async {
    final result = await _channel.invokeMethod('getPairedDevices');
    return List<Map<String, String>>.from(result);
  }

  @override
  Future<List<Map<String, String>>> scanDevices() async {
    final result = await _channel.invokeMethod('scanDevices');
    return (result as List)
        .map((e) => Map<String, String>.from(e.cast<String, String>()))
        .toList();
  }

  @override
  Future<bool> connect(String address) async {
    return await _channel.invokeMethod('connect', {'address': address});
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
  Future<bool> ensurePermissions() async {
    final result = await _channel.invokeMethod('ensurePermissions');
    return result == true;
  }
}

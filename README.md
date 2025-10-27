# bluetooth_serial_android

## English Version

Flutter plugin for **Classic Bluetooth (Serial RFCOMM)** on **Android**.
Allows listing paired devices, scanning nearby ones, connecting, sending, and receiving data over a serial (SPP) connection with non-blocking reads and automatic permission handling.

> Developed by **Carlos Ronny de Sousa** for applications that require serial Bluetooth communication with devices such as HC-05/HC-06, ESP32, Arduinos, thermal printers, and other SPP modules.

---

## ✨ Features

* ✅ Android-only (Classic Bluetooth / RFCOMM)
* ✅ Runtime permission handling (`ensurePermissions`)
* ✅ List paired devices
* ✅ Discover nearby devices (scan)
* ✅ RFCOMM connection (default SPP UUID)
* ✅ Send (`write`) and receive (`read`) data asynchronously
* ✅ Example app with continuous reading loop
* ✅ Compatible with Android 8+ (API 26+)
* 🧪 Example app included in `example/`

> iOS not supported (Classic Bluetooth is not exposed by the public Apple API).

---

## 📦 Installation

In your `pubspec.yaml`:

```yaml
dependencies:
  bluetooth_serial_android: ^1.0.0
```

or, for local development:

```yaml
dependencies:
  bluetooth_serial_android:
    path: ../bluetooth_serial_android
```

---

## 🔧 Requirements and Permissions

The plugin automatically declares and merges the required permissions into your AndroidManifest:

```xml
<uses-permission android:name="android.permission.BLUETOOTH" />
<uses-permission android:name="android.permission.BLUETOOTH_ADMIN" />
<uses-permission android:name="android.permission.BLUETOOTH_SCAN" />
<uses-permission android:name="android.permission.BLUETOOTH_CONNECT" />
<uses-permission android:name="android.permission.ACCESS_FINE_LOCATION" />

<queries>
  <intent>
    <action android:name="android.bluetooth.device.action.FOUND" />
  </intent>
</queries>
```

At runtime, call `FlutterBluetoothSerial.ensurePermissions()` before scanning or connecting.

* Minimum SDK: 26+
* Target SDK: same as your Flutter project
* Kotlin/Gradle: default from Flutter template

---

## 🚀 Quick Start Example

```dart
import 'package:flutter/material.dart';
import 'package:bluetooth_serial_android/bluetooth_serial_android.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await FlutterBluetoothSerial.ensurePermissions();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) =>
      const MaterialApp(debugShowCheckedModeBanner: false, home: DemoPage());
}

class DemoPage extends StatefulWidget {
  const DemoPage({super.key});
  @override
  State<DemoPage> createState() => _DemoPageState();
}

class _DemoPageState extends State<DemoPage> {
  List<Map<String, String>> devices = [];
  String? connectedAddress;
  bool connected = false;
  String buffer = '';
  String received = '';
  String lineEnding = '\n';
  bool _reading = false;

  Future<void> _ensure() async {
    final ok = await FlutterBluetoothSerial.ensurePermissions();
    if (!ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Permissions not granted')),
      );
    }
  }

  Future<void> _scan() async {
    await _ensure();
    final list = await FlutterBluetoothSerial.scanDevices();
    setState(() => devices = list);
  }

  Future<void> _connect(String addr) async {
    await _ensure();
    final ok = await FlutterBluetoothSerial.connect(addr);
    if (ok) {
      setState(() {
        connected = true;
        connectedAddress = addr;
      });
      _readLoop();
    }
  }

  Future<void> _disconnect() async {
    await FlutterBluetoothSerial.disconnect();
    setState(() {
      connected = false;
      connectedAddress = null;
      _reading = false;
    });
  }

  Future<void> _send(String text) async {
    if (!connected) return;
    await FlutterBluetoothSerial.write(text + lineEnding);
  }

  Future<void> _readLoop() async {
    if (_reading) return;
    _reading = true;
    while (connected && _reading) {
      final data = await FlutterBluetoothSerial.read();
      if (data != null && data.isNotEmpty) {
        buffer += data;
        final idx = buffer.indexOf(lineEnding);
        if (idx != -1) {
          final msg = buffer.substring(0, idx).trim();
          buffer = buffer.substring(idx + lineEnding.length);
          setState(() => received = msg);
        }
      }
      await Future.delayed(const Duration(milliseconds: 50));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Bluetooth Serial Android'),
        actions: [
          if (connected)
            IconButton(onPressed: _disconnect, icon: const Icon(Icons.link_off))
          else
            IconButton(onPressed: _scan, icon: const Icon(Icons.refresh)),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              children: devices.map((d) {
                final addr = d['address'] ?? '';
                final isConn = addr == connectedAddress;
                return ListTile(
                  title: Text(d['name'] ?? 'Unnamed'),
                  subtitle: Text(addr),
                  tileColor: isConn ? Colors.lightBlue.withOpacity(0.25) : null,
                  onTap: () => _connect(addr),
                );
              }).toList(),
            ),
          ),
          const Divider(),
          Padding(
            padding: const EdgeInsets.all(8),
            child: Row(
              children: [
                const Text('Line ending:'),
                const SizedBox(width: 8),
                DropdownButton<String>(
                  value: lineEnding,
                  items: const [
                    DropdownMenuItem(value: '\n', child: Text(r'\n')),
                    DropdownMenuItem(value: '\r', child: Text(r'\r')),
                    DropdownMenuItem(value: '\r\n', child: Text(r'\r\n')),
                    DropdownMenuItem(value: '', child: Text('None')),
                  ],
                  onChanged: (v) => setState(() => lineEnding = v ?? '\n'),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8),
            child: TextField(
              decoration: const InputDecoration(
                labelText: 'Message',
                border: OutlineInputBorder(),
              ),
              onSubmitted: _send,
              enabled: connected,
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8),
            child: Text('Received: $received'),
          ),
        ],
      ),
    );
  }
}
```

---

## 🛠️ Plugin API

| Method                                                 | Description                                                   |
| ------------------------------------------------------ | ------------------------------------------------------------- |
| `Future<bool> ensurePermissions()`                     | Checks and requests Bluetooth/Location permissions if needed. |
| `Future<List<Map<String, String>>> getPairedDevices()` | Returns a list of paired devices (`name`, `address`).         |
| `Future<List<Map<String, String>>> scanDevices()`      | Scans for nearby devices and emits `onDeviceFound` events.    |
| `Future<bool> connect(String address)`                 | Connects via RFCOMM/Serial using the default SPP UUID.        |
| `Future<void> disconnect()`                            | Disconnects from the current device.                          |
| `Future<void> write(String message)`                   | Sends data asynchronously.                                    |
| `Future<String?> read()`                               | Reads available data asynchronously. Returns `null` if none.  |

---

## 📚 Best Practices

* Use delimiters (`\n`, `\r`, `\r\n`) to identify message endings.
* Always call `ensurePermissions()` before scanning or connecting.
* Make sure Bluetooth is enabled before scanning.
* Avoid reading on the UI thread.
* Stop reading loops when disconnecting.

---

## ❓ FAQ

**1) Does it work on iOS?**
No. Classic Bluetooth is not available through public iOS APIs.

**2) Why does it request location permissions?**
Required by Android for discovering nearby Bluetooth devices.

**3) Do I need to modify the Manifest?**
No. The plugin merges the necessary permissions automatically.

**4) Does `read()` capture all data at once?**
It reads up to the buffer size (1024 bytes). Use delimiters for message boundaries.

---

## 🧠 Roadmap

* Native `onDataReceived` event stream
* Configurable `read()` timeout
* Adjustable buffer size
* Auto-reconnect feature

---

## 👨‍🏫 Author

**Carlos Ronny de Sousa**
Professor and software developer specializing in Flutter, Android, and IoT.
Focused on practical education and real hardware integration.

---

## 📄 License

MIT License
Copyright (c) 2025 Carlos Ronny de Sousa
See the [LICENSE](LICENSE) file for details.

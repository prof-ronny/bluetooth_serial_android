import 'package:flutter/material.dart';
import 'package:bluetooth_serial_android/bluetooth_serial_android.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // ✅ Agora usa o ensurePermissions do plugin
  final ok = await FlutterBluetoothSerial.ensurePermissions();
  debugPrint('Permissões Bluetooth: ${ok ? "OK" : "Aguardando autorização"}');

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) =>
      const MaterialApp(debugShowCheckedModeBanner: false, home: BluetoothPage());
}

class BluetoothPage extends StatefulWidget {
  const BluetoothPage({super.key});
  @override
  State<BluetoothPage> createState() => _BluetoothPageState();
}

class _BluetoothPageState extends State<BluetoothPage> {
  List<Map<String, String>> devices = [];
  bool scanning = false;
  bool connected = false;
  String? connectedAddress;
  String received = '';
  String buffer = '';
  String lineEnding = '\\n';
  bool reading = false;

  // ============================================================
  //                    SCAN E CONEXÃO
  // ============================================================
  Future<void> _scan() async {
    setState(() {
      scanning = true;
      devices.clear();
    });

    try {
      final result = await FlutterBluetoothSerial.scanDevices();
      setState(() => devices = result);
    } finally {
      setState(() => scanning = false);
    }
  }

  Future<void> _connect(String addr) async {
    final ok = await FlutterBluetoothSerial.connect(addr);
    if (ok) {
      setState(() {
        connected = true;
        connectedAddress = addr;
      });
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Conectado com $addr')));
      _startReadLoop();
    } else {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Falha na conexão')));
    }
  }

  Future<void> _disconnect() async {
    await FlutterBluetoothSerial.disconnect();
    setState(() {
      connected = false;
      connectedAddress = null;
      reading = false;
    });
  }

  // ============================================================
  //                    LEITURA CONTÍNUA
  // ============================================================
  Future<void> _startReadLoop() async {
    if (reading) return;
    reading = true;
    buffer = '';

    while (connected && reading) {
      try {
        final data = await FlutterBluetoothSerial.read();
        if (data != null && data.isNotEmpty) {
          buffer += data;
          if (_hasLineEnding(buffer)) {
            final msg = _extractMessage();
            setState(() => received = msg);
          }
        }
      } catch (_) {
        break;
      }
      await Future.delayed(const Duration(milliseconds: 50));
    }
  }

  bool _hasLineEnding(String str) {
    switch (lineEnding) {
      case '\\n':
        return str.contains('\n');
      case '\\r':
        return str.contains('\r');
      case '\\r\\n':
        return str.contains('\r\n');
      default:
        return true; // sem delimitador
    }
  }

  String _extractMessage() {
    String msg = buffer;
    switch (lineEnding) {
      case '\\n':
        msg = buffer.substring(0, buffer.indexOf('\n') + 1);
        buffer = buffer.substring(buffer.indexOf('\n') + 1);
        break;
      case '\\r':
        msg = buffer.substring(0, buffer.indexOf('\r') + 1);
        buffer = buffer.substring(buffer.indexOf('\r') + 1);
        break;
      case '\\r\\n':
        msg = buffer.substring(0, buffer.indexOf('\r\n') + 2);
        buffer = buffer.substring(buffer.indexOf('\r\n') + 2);
        break;
      default:
        buffer = '';
    }
    return msg.trim();
  }

  // ============================================================
  //                    ENVIO DE DADOS
  // ============================================================
  Future<void> _send(String msg) async {
    if (!connected) return;
    final fullMsg = msg + _endingSymbol();
    await FlutterBluetoothSerial.write(fullMsg);
  }

  String _endingSymbol() {
    switch (lineEnding) {
      case '\\n':
        return '\n';
      case '\\r':
        return '\r';
      case '\\r\\n':
        return '\r\n';
      default:
        return '';
    }
  }

  // ============================================================
  //                    INTERFACE
  // ============================================================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Bluetooth Serial'),
        actions: [
          if (connected)
            IconButton(
              icon: const Icon(Icons.link_off),
              onPressed: _disconnect,
              tooltip: 'Desconectar',
            )
          else
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: _scan,
              tooltip: 'Buscar dispositivos',
            ),
        ],
      ),
      body: Column(
        children: [
          if (scanning)
            const Padding(
              padding: EdgeInsets.all(16),
              child: CircularProgressIndicator(),
            )
          else
            Expanded(
              child: ListView.builder(
                itemCount: devices.length,
                itemBuilder: (context, i) {
                  final d = devices[i];
                  final addr = d['address'] ?? '';
                  final isConnected = addr == connectedAddress;
                  return ListTile(
                    title: Text(d['name'] ?? 'Sem nome'),
                    subtitle: Text(addr),
                    tileColor: isConnected
                        ? Colors.lightBlue.withOpacity(0.3)
                        : null,
                    onTap: () => _connect(addr),
                  );
                },
              ),
            ),
          const Divider(),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              children: [
                const Text('Fim de linha: '),
                DropdownButton<String>(
                  value: lineEnding,
                  items: const [
                    DropdownMenuItem(value: '\\n', child: Text('\\n')),
                    DropdownMenuItem(value: '\\r', child: Text('\\r')),
                    DropdownMenuItem(value: '\\r\\n', child: Text('\\r\\n')),
                    DropdownMenuItem(value: 'none', child: Text('Nenhum')),
                  ],
                  onChanged: (v) => setState(() => lineEnding = v!),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              decoration: const InputDecoration(
                labelText: 'Mensagem para enviar',
                border: OutlineInputBorder(),
              ),
              onSubmitted: _send,
              enabled: connected,
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Text(
              'Recebido: $received',
              style: const TextStyle(fontSize: 16),
            ),
          ),
        ],
      ),
    );
  }
}

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:bluetooth_serial_android/bluetooth_serial_android.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final ok = await FlutterBluetoothSerial.ensurePermissions();
  debugPrint('Permissões Bluetooth: ${ok ? "OK" : "Aguardando autorização"}');
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) => const MaterialApp(
        debugShowCheckedModeBanner: false,
        home: BluetoothPage(),
      );
}

class BluetoothPage extends StatefulWidget {
  const BluetoothPage({super.key});
  @override
  State<BluetoothPage> createState() => _BluetoothPageState();
}

class _BluetoothPageState extends State<BluetoothPage> {
  // Dispositivos
  List<Map<String, String>> devices = [];
  bool scanning = false;

  // Conexão
  bool connected = false;
  String? connectedAddress;

  // Config de conexão
  final _uuidCtrl =
      TextEditingController(text: '00001101-0000-1000-8000-00805F9B34FB');
  final _timeoutCtrl = TextEditingController(text: '200');

  // Envio / Leitura
  final _sendCtrl = TextEditingController();
  String lineEnding = '\n'; // '\n', '\r', '\r\n' ou ''
  bool readingLoop = false;
  final List<String> logs = [];

  // ----------------------------------------------------------
  // Scan
  // ----------------------------------------------------------
  Future<void> _scan() async {
    setState(() {
      scanning = true;
      devices.clear();
    });
    try {
      final result = await FlutterBluetoothSerial.scanDevices();
      setState(() => devices = result);
    } catch (e) {
      _toast('Falha no scan: $e');
    } finally {
      setState(() => scanning = false);
    }
  }

  // ----------------------------------------------------------
  // Conectar / Desconectar
  // ----------------------------------------------------------
  Future<void> _connect(String addr) async {
    final uuid = _uuidCtrl.text.trim().isEmpty
        ? '00001101-0000-1000-8000-00805F9B34FB'
        : _uuidCtrl.text.trim();

    final timeout = int.tryParse(_timeoutCtrl.text.trim()) ?? 200;

    try {
      final ok = await FlutterBluetoothSerial.connect(
        addr,
        uuid: uuid,
        timeoutMs: timeout,
      );
      if (ok) {
        setState(() {
          connected = true;
          connectedAddress = addr;
        });
        _toast('Conectado com $addr');
      } else {
        _toast('Falha na conexão');
      }
    } catch (e) {
      _toast('Erro ao conectar: $e');
    }
  }

  Future<void> _disconnect() async {
    try {
      await FlutterBluetoothSerial.disconnect();
    } finally {
      setState(() {
        connected = false;
        connectedAddress = null;
        readingLoop = false;
      });
      _toast('Desconectado');
    }
  }

  // ----------------------------------------------------------
  // Leitura (uma vez)
  // ----------------------------------------------------------
  Future<void> _readOnce() async {
    if (!connected) return;
    try {
      final data = await FlutterBluetoothSerial.read();
      final msg = data ?? '<null/timeout>';
      _pushLog('[read] $msg');
    } catch (e) {
      _pushLog('[read] erro: $e');
    }
  }

  // Leitura de linha (uma vez) com delimitador
  Future<void> _readLineOnce() async {
    if (!connected) return;
    final delimiter = lineEnding; // usa a seleção atual
    try {
      final data = await FlutterBluetoothSerial.readLine(delimiter);
      final msg = data ?? '<null/timeout/sem linha completa>';
      _pushLog('[readLine] $msg');
    } catch (e) {
      _pushLog('[readLine] erro: $e');
    }
  }

  // ----------------------------------------------------------
  // Loop de leitura contínua (usando read())
  // ----------------------------------------------------------
  Future<void> _startReadLoop() async {
    if (!connected || readingLoop) return;
    setState(() => readingLoop = true);
    _pushLog('--- iniciar leitura contínua (read) ---');

    while (connected && readingLoop) {
      try {
        final data = await FlutterBluetoothSerial.read();
        if (data != null && data.isNotEmpty) {
          _pushLog('[loop] $data');
        }
      } catch (e) {
        _pushLog('[loop] erro: $e');
        break;
      }
      await Future.delayed(const Duration(milliseconds: 40));
    }

    _pushLog('--- loop de leitura encerrado ---');
    if (mounted) setState(() => readingLoop = false);
  }

  void _stopReadLoop() {
    if (!readingLoop) return;
    setState(() => readingLoop = false);
  }

  // ----------------------------------------------------------
  // Envio
  // ----------------------------------------------------------
  Future<void> _send() async {
    if (!connected) return;
    final msg = _sendCtrl.text;
    final full = msg + lineEnding;
    try {
      await FlutterBluetoothSerial.write(full);
      _pushLog('[write] "$msg" (fim: ${_endingLabel(lineEnding)})');
      _sendCtrl.clear();
    } catch (e) {
      _pushLog('[write] erro: $e');
    }
  }

  // ----------------------------------------------------------
  // UI helpers
  // ----------------------------------------------------------
  void _toast(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  void _pushLog(String line) {
    if (!mounted) return;
    setState(() {
      logs.add(line);
      if (logs.length > 1000) {
        logs.removeRange(0, logs.length - 1000);
      }
    });
  }

  String _endingLabel(String v) {
    if (v == '\n') return r'\n';
    if (v == '\r') return r'\r';
    if (v == '\r\n') return r'\r\n';
    return 'none';
  }

  // ----------------------------------------------------------
  // Build
  // ----------------------------------------------------------
  @override
  Widget build(BuildContext context) {
    final isConnected = connected && connectedAddress != null;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Bluetooth Serial (Exemplo)'),
        actions: [
          if (!isConnected)
            IconButton(
              icon: const Icon(Icons.refresh),
              tooltip: 'Buscar dispositivos',
              onPressed: _scan,
            ),
          if (isConnected)
            IconButton(
              icon: const Icon(Icons.link_off),
              tooltip: 'Desconectar',
              onPressed: _disconnect,
            ),
        ],
      ),
      body: Column(
        children: [
          // -----------------------------------------
          // Config de conexão
          // -----------------------------------------
          Container(
            color: const Color.fromARGB(255, 255, 255, 255),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 6),
              child: Row(
                children: [
                  Flexible(
                    flex: 3,
                    child: TextField(
                      controller: _uuidCtrl,
                      decoration: const InputDecoration(
                        labelText: 'UUID (SPP default)',
                        border: OutlineInputBorder(),
                        hintText: '00001101-0000-1000-8000-00805F9B34FB',
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: _timeoutCtrl,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Timeout (ms)',
                        border: OutlineInputBorder(),
                        hintText: '200',
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // -----------------------------------------
          // Lista de dispositivos
          // -----------------------------------------
          if (scanning)
            const Padding(
              padding: EdgeInsets.all(16),
              child: CircularProgressIndicator(),
            )
          else
            Flexible(
              child: SizedBox(
                height: 180,
                child: ListView.builder(
                  itemCount: devices.length,
                  itemBuilder: (context, i) {
                    final d = devices[i];
                    final addr = d['address'] ?? '';
                    final isThis = addr == connectedAddress;
                    return ListTile(
                      dense: true,
                      title: Text(d['name'] ?? 'Sem nome'),
                      subtitle: Text(addr),
                      tileColor:
                          isThis ? Colors.lightBlue.withOpacity(0.25) : null,
                      onTap: isConnected ? null : () => _connect(addr),
                      trailing: isThis
                          ? const Icon(Icons.link, color: Colors.blue)
                          : null,
                    );
                  },
                ),
              ),
            ),

          const Divider(height: 1),

          // -----------------------------------------
          // Controles de leitura e envio
          // -----------------------------------------
          Container(
            color: const Color.fromARGB(255, 255, 255, 255),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 6),
              child: Row(
                children: [
                  const Text('Fim de linha: '),
                  const SizedBox(width: 8),
                  DropdownButton<String>(
                    value: lineEnding,
                    onChanged: (v) => setState(() => lineEnding = v ?? ''),
                    items: const [
                      DropdownMenuItem(value: '\n', child: Text(r'\n')),
                      DropdownMenuItem(value: '\r', child: Text(r'\r')),
                      DropdownMenuItem(value: '\r\n', child: Text(r'\r\n')),
                      DropdownMenuItem(value: '', child: Text('none')),
                    ],
                  ),
                ],
              ),
            ),
          ),
          Container(
            color: const Color.fromARGB(255, 255, 255, 255),
            child: Row(
              children: [
                ElevatedButton(
                  onPressed: isConnected ? _readOnce : null,
                  child: const Text('read() 1x'),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: isConnected ? _readLineOnce : null,
                  child: const Text('readLine() 1x'),
                ),
              ],
            ),
          ),

          Container(
            color: const Color.fromARGB(255, 255, 255, 255),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 6),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _sendCtrl,
                      enabled: isConnected,
                      decoration: const InputDecoration(
                        labelText: 'Mensagem',
                        border: OutlineInputBorder(),
                      ),
                      onSubmitted: (_) => _send(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: isConnected ? _send : null,
                    child: const Text('Enviar'),
                  ),
                ],
              ),
            ),
          ),

          Container(
            color: const Color.fromARGB(255, 255, 255, 255),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
              child: Row(
                children: [
                  ElevatedButton.icon(
                    icon: const Icon(Icons.play_arrow),
                    onPressed:
                        (isConnected && !readingLoop) ? _startReadLoop : null,
                    label: const Text('Iniciar leitura contínua (read)'),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.stop),
                    onPressed: readingLoop ? _stopReadLoop : null,
                    label: const Text('Parar'),
                  ),
                ],
              ),
            ),
          ),

          const Divider(height: 1),

          // -----------------------------------------
          // Logs recebidos
          // -----------------------------------------
          Container(
            color: const Color.fromARGB(255, 250, 250, 250),
            child: Flexible(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
                child: Row(
                  children: [
                    const Text('Logs recebidos:'),
                    const SizedBox(width: 8),
                    if (connectedAddress != null)
                      Text(
                        '[$connectedAddress]',
                        style: const TextStyle(fontStyle: FontStyle.italic),
                      ),
                  ],
                ),
              ),
            ),
          ),

          Flexible(
            child: Container(
              width: double.infinity,
              color: const Color(0xFFF6F8FA),
              child: ListView.builder(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                itemCount: logs.length,
                itemBuilder: (context, i) => Text(
                  logs[i],
                  style: const TextStyle(fontFamily: 'monospace'),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _uuidCtrl.dispose();
    _timeoutCtrl.dispose();
    _sendCtrl.dispose();
    super.dispose();
  }
}

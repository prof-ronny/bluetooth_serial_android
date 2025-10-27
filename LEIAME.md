# bluetooth_serial_android

Plugin Flutter para **Bluetooth Clássico (Serial RFCOMM)** no **Android**.
Permite listar dispositivos pareados, buscar (scan), conectar, enviar e receber dados via porta serial (SPP) com leitura não bloqueante e gerenciamento automático de permissões.

> Desenvolvido por **Carlos Ronny de Sousa** para aplicações que necessitam de comunicação serial Bluetooth com dispositivos como HC-05/HC-06, ESP32, Arduinos, impressoras térmicas e outros módulos SPP.

---

## ✨ Recursos

* ✅ Android-only (Bluetooth Clássico / RFCOMM)
* ✅ Permissões em runtime pelo próprio plugin (`ensurePermissions`)
* ✅ Listagem de dispositivos pareados
* ✅ Scan de dispositivos próximos com callback incremental
* ✅ Conexão RFCOMM (UUID SPP padrão)
* ✅ Envio (`write`) e leitura (`read`) sem travar a UI
* ✅ Exemplo de leitura contínua (loop no app)
* ✅ Compatível com Android 8+ (API 26+)
* 🧪 App de exemplo incluído em `example/`

> iOS não suportado (Bluetooth Clássico não é exposto pela API pública da Apple).

---

## 📦 Instalação

No seu `pubspec.yaml`:

```yaml
dependencies:
  bluetooth_serial_android: ^1.0.0
```

ou, durante o desenvolvimento local:

```yaml
dependencies:
  bluetooth_serial_android:
    path: ../bluetooth_serial_android
```

---

## 🔧 Requisitos e permissões

O plugin já declara no Manifest as permissões necessárias e o Android vai mesclar automaticamente com o app:

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

Em runtime, chame `FlutterBluetoothSerial.ensurePermissions()` antes de escanear ou conectar.

* Min SDK recomendado: 26+
* Target SDK: o mesmo do seu projeto Flutter
* Kotlin/Gradle: padrão do template recente do Flutter

---

## 🚀 Uso rápido

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
        const SnackBar(content: Text('Permissões não concedidas')),
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
                  title: Text(d['name'] ?? 'Sem nome'),
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
                const Text('Fim de linha:'),
                const SizedBox(width: 8),
                DropdownButton<String>(
                  value: lineEnding,
                  items: const [
                    DropdownMenuItem(value: '\n', child: Text(r'\n')),
                    DropdownMenuItem(value: '\r', child: Text(r'\r')),
                    DropdownMenuItem(value: '\r\n', child: Text(r'\r\n')),
                    DropdownMenuItem(value: '', child: Text('Nenhum')),
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
                labelText: 'Mensagem',
                border: OutlineInputBorder(),
              ),
              onSubmitted: _send,
              enabled: connected,
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8),
            child: Text('Recebido: $received'),
          ),
        ],
      ),
    );
  }
}
```

---

## 🔧 API do plugin

| Método                                                 | Descrição                                                                    |
| ------------------------------------------------------ | ---------------------------------------------------------------------------- |
| `Future<bool> ensurePermissions()`                     | Verifica e solicita, se necessário, as permissões Bluetooth/Localização.     |
| `Future<List<Map<String, String>>> getPairedDevices()` | Lista dispositivos já pareados (`name`, `address`).                          |
| `Future<List<Map<String, String>>> scanDevices()`      | Busca dispositivos próximos. Também emite eventos "onDeviceFound" (interno). |
| `Future<bool> connect(String address)`                 | Conecta via RFCOMM/Serial usando UUID SPP padrão.                            |
| `Future<void> disconnect()`                            | Fecha a conexão atual.                                                       |
| `Future<void> write(String message)`                   | Envia dados (assíncrono, não bloqueia a UI).                                 |
| `Future<String?> read()`                               | Lê dados disponíveis (assíncrono). Retorna `null` se nada for recebido.      |

---

## 📚 Boas práticas

* Use delimitadores (`\n`, `\r`, `\r\n`) para identificar fim de mensagem.
* Chame `ensurePermissions()` antes de `scan` ou `connect`.
* Garanta que o Bluetooth esteja ligado.
* Evite chamar `read()` na UI Thread.
* Ao desconectar, pare loops de leitura.

---

## ❓ Perguntas frequentes

**1) Funciona no iOS?**
Não. O iOS não expõe API pública para Bluetooth Clássico.

**2) Por que pede localização?**
Exigência do Android para descoberta de dispositivos Bluetooth próximos.

**3) Preciso editar o Manifest?**
Não. O Manifest do plugin é mesclado automaticamente.

**4) A leitura captura tudo de uma vez?**
Lê até o tamanho do buffer (1024 bytes). Use delimitadores.

---

## 🧩 Exemplo de erros comuns

* **MissingPluginException**
  Verifique o nome do canal (`bluetooth_serial_android`) e rode `flutter clean`.

* **Nada aparece no scan**
  Verifique permissões e Bluetooth ativado.

* **App trava ao ler**
  Atualize o plugin. O método `read()` agora roda em thread separada.

---

## 🧠 Roadmap futuro

* Evento `onDataReceived` nativo (push)
* Timeout configurável no `read()`
* Buffer configurável
* Reconexão automática

---

## 👨‍🎓 Autor

**Carlos Ronny de Sousa**
Professor e desenvolvedor Flutter/Android/IoT.
Foco em ensino prático e integração de hardware.

---

## 🔄 Licença

MIT License
Copyright (c) 2025 Carlos Ronny de Sousa
Consulte o arquivo [LICENSE](LICENSE) para detalhes.

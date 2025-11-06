# bluetooth_serial_android

## English Version

Flutter plugin for **Classic Bluetooth (Serial RFCOMM)** on **Android**.
Allows listing paired devices, scanning nearby ones, connecting, sending, and receiving data over a serial (SPP) connection with non-blocking reads and automatic permission handling.

> Developed by **Carlos Ronny de Sousa** for applications that require serial Bluetooth communication with devices such as HC-05/HC-06, ESP32, Arduinos, thermal printers, and other SPP modules.

---

## ✨ Features

* ✅ Android-only (Classic Bluetooth / RFCOMM)
* ✅ Automatic runtime permissions (`ensurePermissions`)
* ✅ List paired devices
* ✅ Scan for nearby devices
* ✅ RFCOMM connection (default SPP UUID)
* ✅ Custom UUID support in `connect()`
* ✅ Configurable read timeout in `connect()`
* ✅ Send (`write`) and receive (`read`) async (non-blocking)
* ✅ Read full lines with `readLine()` and custom delimiter
* ✅ Example app with continuous reading loop
* ✅ Compatible with Android 8+ (API 26+)
* 🧪 Example included in `example/`

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


📘 Bluetooth Serial Cookbook (Version S – minimal & practical)

1️⃣ **Permissions**  
When to use: Always at app startup.

```dart
await FlutterBluetoothSerial.ensurePermissions();
```

2️⃣ **List paired devices**
When to use: Show already paired devices.

```dart
final devices = await FlutterBluetoothSerial.getPairedDevices();
for (final d in devices) {
  print("${d['name']} - ${d['address']}");
}
```

3️⃣ **Scan + onDeviceFound event**
When to use: Discover nearby devices.

```dart
FlutterBluetoothSerial.scanDevices().then((list) {
  print("Scan finished, found: ${list.length}");
});

FlutterBluetoothSerial.onDeviceFound.listen((d) {
  print("Found: ${d['name']} - ${d['address']}");
});
```

4️⃣ **Connect (with custom UUID & timeout)**
When to use: Connect to HC-05, ESP32, printer, etc.

```dart
final ok = await FlutterBluetoothSerial.connect(
  "00:22:11:AA:BB:CC",
  uuid: "00001101-0000-1000-8000-00805F9B34FB",
  timeoutMs: 300,
);
print(ok ? "Connected" : "Failed");
```

5️⃣ **Send data (write)**
When to use: Simple command or text.

```dart
await FlutterBluetoothSerial.write("LED_ON\n");
```

6️⃣ **Read once (`read()`)**
When to use: One-time read.

```dart
final data = await FlutterBluetoothSerial.read();
print("Received: $data");
```

7️⃣ **Read line (`readLine()`) with delimiter**
When to use: When the device sends complete lines.

```dart
final line = await FlutterBluetoothSerial.readLine("\n");
print("Line: $line");
```

8️⃣ **Simple read loop**
When to use: Continuous monitoring.

```dart
bool reading = true;
while (reading) {
  final data = await FlutterBluetoothSerial.read();
  if (data != null) print(">> $data");
  await Future.delayed(const Duration(milliseconds: 50));
}
```

9️⃣ **Disconnect**
When to use: End session.

```dart
await FlutterBluetoothSerial.disconnect();
print("Disconnected");
```



---

## 🛠️ Plugin API

| Method                                                                 | Description                                                                                   |
|------------------------------------------------------------------------|-----------------------------------------------------------------------------------------------|
| `Future<bool> ensurePermissions()`                                     | Checks and requests Bluetooth/Location permissions if needed.                                 |
| `Future<List<Map<String, String>>> getPairedDevices()`                 | Returns a list of paired devices (`name`, `address`).                                         |
| `Future<List<Map<String, String>>> scanDevices()`                      | Scans for nearby devices and returns the list found.                                          |
| `Future<bool> connect(String address, {String uuid, int timeoutMs})`   | Connects using RFCOMM/Serial. Supports custom UUID and read timeout.                          |
| `Future<void> disconnect()`                                            | Disconnects from the current device and clears buffers.                                       |
| `Future<void> write(String message)`                                   | Sends data asynchronously (non-blocking).                                                     |
| `Future<String?> read()`                                               | Reads up to 1024 bytes asynchronously. Returns `null` on timeout or no data.                  |
| `Future<String?> readLine([String delimiter = '\n'])`                  | Reads until a full line (based on the delimiter) is received. Returns `null` on timeout.      |

---

## 📚 Best Practices

* Always call `ensurePermissions()` before using `scan()` or `connect()` (the plugin will request permissions automatically when needed, but calling it at app startup is recommended).
* Prefer using delimiter-based reading with `readLine()` when possible — it reduces the need to manually manage incoming buffer fragments.
* If using `read()` in a loop, include a small delay (e.g., 30–80ms) to avoid high CPU usage.
* Use delimiters (`\n`, `\r`, or `\r\n`) to detect complete messages from the device.
* If your device uses a custom UUID instead of the default SPP UUID, pass the custom UUID when calling `connect()`.
* Adjust the `timeoutMs` in `connect()` based on how long the target device typically takes to respond.
* Always stop any active read loops **before** calling `disconnect()`.
* Use `disconnect()` to properly clear buffers and close streams.
* Avoid calling `read()` simultaneously from multiple places — use a single central read loop instead.


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

### ✅ Completed
* Support for custom UUID in `connect()`
* `readLine(delimiter)` with internal buffer
* Timeout support in `connect(timeoutMs)`

### 🚧 In Progress / Planned
* Native `onDataReceived` event stream (no need for manual read loop)
* Connection status stream (onConnect / onDisconnect events)


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


# bluetooth_serial_android

## Pt-Br Versão

Plugin Flutter para **Bluetooth Clássico (Serial RFCOMM)** no **Android**.
Permite listar dispositivos pareados, buscar (scan), conectar, enviar e receber dados via porta serial (SPP) com leitura não bloqueante e gerenciamento automático de permissões.

> Desenvolvido por **Carlos Ronny de Sousa** para aplicações que necessitam de comunicação serial Bluetooth com dispositivos como HC-05/HC-06, ESP32, Arduinos, impressoras térmicas e outros módulos SPP.

---

## ✨ Recursos

* ✅ Somente Android (Bluetooth Clássico / RFCOMM)
* ✅ Permissões automáticas em runtime (`ensurePermissions`)
* ✅ Lista dispositivos pareados
* ✅ Busca dispositivos próximos (scan)
* ✅ Conexão RFCOMM (UUID SPP padrão)
* ✅ Suporte a UUID customizado no `connect()`
* ✅ Timeout de leitura configurável no `connect()`
* ✅ Envio (`write`) e leitura (`read`) assíncrona (não bloqueante)
* ✅ Leitura de linha com `readLine()` e delimitador customizado
* ✅ Exemplo com loop contínuo de leitura
* ✅ Compatível com Android 8+ (API 26+)
* 🧪 Exemplo incluído em `example/`

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

📘 Bluetooth Serial Cookbook (Versão S – mínima e prática)

1️⃣ **Permissões**  
Quando usar: Sempre ao iniciar o app.

```dart
await FlutterBluetoothSerial.ensurePermissions();
```

2️⃣ **Listar pareados**
Quando usar: Mostrar dispositivos já pareados.

```dart
final devices = await FlutterBluetoothSerial.getPairedDevices();
for (final d in devices) {
  print("${d['name']} - ${d['address']}");
}
```

3️⃣ **Scan + evento de dispositivo encontrado**
Quando usar: Descobrir dispositivos próximos.

```dart
FlutterBluetoothSerial.scanDevices().then((list) {
  print("Scan terminou, encontrados: ${list.length}");
});

FlutterBluetoothSerial.onDeviceFound.listen((d) {
  print("Encontrado: ${d['name']} - ${d['address']}");
});
```

4️⃣ **Conectar (com UUID custom e timeout)**
Quando usar: Conectar a um HC-05, ESP32, impressora, etc.

```dart
final ok = await FlutterBluetoothSerial.connect(
  "00:22:11:AA:BB:CC",
  uuid: "00001101-0000-1000-8000-00805F9B34FB",
  timeoutMs: 300,
);
print(ok ? "Conectado" : "Falhou");
```

5️⃣ **Enviar dados (write)**
Quando usar: Envio simples de comando ou texto.

```dart
await FlutterBluetoothSerial.write("LED_ON\n");
```

6️⃣ **Ler uma vez (`read()`)**
Quando usar: Leitura pontual.

```dart
final data = await FlutterBluetoothSerial.read();
print("Recebido: $data");
```

7️⃣ **Ler linha (`readLine()`) com delimitador**
Quando usar: Quando o dispositivo envia linhas concluídas.

```dart
final line = await FlutterBluetoothSerial.readLine("\n");
print("Linha: $line");
```

8️⃣ **Loop simples de leitura**
Quando usar: Para monitorar continuamente.

```dart
bool reading = true;
while (reading) {
  final data = await FlutterBluetoothSerial.read();
  if (data != null) print(">> $data");
  await Future.delayed(const Duration(milliseconds: 50));
}
```

9️⃣ **Desconectar**
Quando usar: Finalizar sessão.

```dart
await FlutterBluetoothSerial.disconnect();
print("Desconectado");

```


---

## 🛠️ API do Plugin

| Método                                                                  | Descrição                                                                                               |
|-------------------------------------------------------------------------|---------------------------------------------------------------------------------------------------------|
| `Future<bool> ensurePermissions()`                                      | Verifica e solicita permissões de Bluetooth e Localização quando necessário.                            |
| `Future<List<Map<String, String>>> getPairedDevices()`                  | Retorna uma lista de dispositivos pareados (`name`, `address`).                                         |
| `Future<List<Map<String, String>>> scanDevices()`                       | Realiza busca (scan) e retorna a lista de dispositivos encontrados.                                     |
| `Future<bool> connect(String address, {String uuid, int timeoutMs})`    | Conecta via RFCOMM/Serial. Suporta UUID customizado e timeout de leitura configurável.                  |
| `Future<void> disconnect()`                                             | Desconecta do dispositivo atual e limpa buffers.                                                        |
| `Future<void> write(String message)`                                    | Envia dados de forma assíncrona (não bloqueante).                                                       |
| `Future<String?> read()`                                                | Lê até 1024 bytes de forma assíncrona. Retorna `null` em timeout ou se não houver dados.                |
| `Future<String?> readLine([String delimiter = '\n'])`                   | Lê até receber uma linha completa (com base no delimitador). Retorna `null` em timeout.                 |


---

## 📚 Boas Práticas

* Sempre chame `ensurePermissions()` antes de fazer `scan` ou `connect()` (o plugin já tenta solicitar automaticamente, mas é recomendado chamar no início do app).
* Prefira usar leitura com delimitador (`readLine()`) quando possível — reduz necessidade de tratar buffers manualmente.
* Se usar `read()` em loop, inclua um `delay` pequeno (ex: 30–80ms) para evitar alto consumo de CPU.
* Utilize delimitadores (`\n`, `\r` ou `\r\n`) para identificar mensagens completas do dispositivo.
* Se o dispositivo usa um UUID diferente do SPP padrão, passe o UUID customizado no `connect()`.
* Ajuste o `timeoutMs` do `connect()` conforme o tempo que o dispositivo costuma demorar para responder.
* Sempre pare loops de leitura **antes** de chamar `disconnect()`.
* Use `disconnect()` para limpar buffer e fechar streams corretamente.
* Evite chamar `read()` simultaneamente em vários locais — prefira um único loop central de leitura.

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

## 🧠 Roadmap

### ✅ Concluído
* Suporte a UUID customizado no `connect()`
* `readLine(delimiter)` com buffer interno
* Suporte a timeout no `connect(timeoutMs)`

### 🚧 Em andamento / Planejado
* Evento nativo `onDataReceived` (stream, sem precisar de loop manual)
* Stream de status de conexão (onConnect / onDisconnect)


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


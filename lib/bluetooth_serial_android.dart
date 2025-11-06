import 'bluetooth_serial_android_platform_interface.dart';

/// API principal para comunicação Bluetooth Serial (RFCOMM) no Android.
///
/// Esta classe fornece métodos estáticos para solicitar permissões, listar
/// dispositivos, buscar novos dispositivos, conectar, enviar e receber dados
/// via Bluetooth Clássico.
class FlutterBluetoothSerial {
  /// Verifica e solicita permissões necessárias para uso do Bluetooth no Android.
  ///
  /// Retorna `true` caso as permissões já tenham sido concedidas
  /// ou se o usuário as conceder após a solicitação.
  static Future<bool> ensurePermissions() {
    return BluetoothSerialPlatform.instance.ensurePermissions();
  }

  /// Retorna a lista de dispositivos Bluetooth já pareados com o telefone.
  ///
  /// Cada item da lista contém:
  /// * `name`: nome do dispositivo
  /// * `address`: MAC address
  static Future<List<Map<String, String>>> getPairedDevices() {
    return BluetoothSerialPlatform.instance.getPairedDevices();
  }

  /// Inicia a busca (scan) por dispositivos Bluetooth próximos.
  ///
  /// Quando dispositivos forem encontrados, o plugin poderá emitir eventos
  /// através de `onDeviceFound` (dependendo da implementação da plataforma).
  ///
  /// Retorna uma lista final de dispositivos ao concluir a busca.
  static Future<List<Map<String, String>>> scanDevices() {
    return BluetoothSerialPlatform.instance.scanDevices();
  }

  /// Conecta a um dispositivo Bluetooth utilizando o endereço MAC informado.
  ///
  /// [address] é obrigatório e deve ser o MAC Address do dispositivo (ex: `00:11:22:AA:BB:CC`).
  ///
  /// [uuid] permite definir um UUID customizado para dispositivos que não utilizam
  /// o padrão SPP. Por padrão, usa o UUID `00001101-0000-1000-8000-00805F9B34FB`.
  ///
  /// [timeoutMs] define o tempo máximo de tentativa de conexão antes de gerar erro.
  ///
  /// Retorna `true` caso a conexão seja bem-sucedida.
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

  /// Encerra a conexão Bluetooth atual e libera recursos.
  static Future<void> disconnect() {
    return BluetoothSerialPlatform.instance.disconnect();
  }

  /// Envia dados para o dispositivo conectado via Bluetooth.
  ///
  /// Não adiciona automaticamente quebras de linha.
  /// Caso necessário, inclua `\n`, `\r` ou `\r\n` manualmente.
  static Future<void> write(String message) {
    return BluetoothSerialPlatform.instance.write(message);
  }

  /// Lê dados recebidos do dispositivo Bluetooth.
  ///
  /// Retorna:
  /// * String com dados recebidos
  /// * `null` caso nenhum dado esteja disponível ou em timeout
  static Future<String?> read() {
    return BluetoothSerialPlatform.instance.read();
  }

  /// Lê uma linha completa com base em um delimitador, como `\n`, `\r` ou `\r\n`.
  ///
  /// Útil para dispositivos que enviam mensagens finalizadas por caractere especial.
  ///
  /// Retorna:
  /// * A linha sem o delimitador
  /// * `null` caso ocorra timeout ou a linha não esteja completa ainda
  static Future<String?> readLine([String delimiter = "\n"]) {
    return BluetoothSerialPlatform.instance.readLine(delimiter);
  }
}

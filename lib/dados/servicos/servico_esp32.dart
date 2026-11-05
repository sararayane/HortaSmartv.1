/// Ponto de integração lógica com o ESP32.
///
/// Na arquitetura prevista, o aplicativo envia configurações à nuvem e o
/// ESP32 consulta essas configurações. O controle físico deve ser validado
/// no próprio ESP32; o app não deve depender de uma tela aberta para irrigar.
class ServicoEsp32 {
  ServicoEsp32();

  Future<void> solicitarIrrigacao({
    required String idCanteiro,
    required bool ligar,
  }) async {
    // TODO: enviar comando por Firebase/MQTT/API autenticada.
    throw UnimplementedError('Integração com ESP32 ainda não implementada.');
  }
}

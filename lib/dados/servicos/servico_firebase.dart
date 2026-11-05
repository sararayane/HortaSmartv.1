/// Ponto de integração para o Firebase.
///
/// Esta classe ainda não inicializa o Firebase nem faz chamadas de rede.
/// Quando a interface estiver validada, adicionaremos firebase_core,
/// cloud_firestore e/ou firebase_database conforme a arquitetura escolhida.
class ServicoFirebase {
  ServicoFirebase();

  Future<void> salvarMetaUmidade({
    required String idCanteiro,
    required double meta,
  }) async {
    // TODO: gravar a meta em uma coleção/caminho por canteiro.
    throw UnimplementedError('Integração Firebase ainda não implementada.');
  }
}

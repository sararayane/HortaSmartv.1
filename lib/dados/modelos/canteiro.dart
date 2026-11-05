enum ModoIrrigacao { automatico, manual }

class Canteiro {
  const Canteiro({
    required this.id,
    required this.nome,
    required this.cultura,
    required this.umidadeAtual,
    required this.metaUmidade,
    required this.conectado,
    required this.irrigando,
    required this.modo,
    required this.intervaloHoras,
    required this.valorSeco,
    required this.valorMolhado,
    this.caminhoImagem,
    this.imagemBase64,
  });

  final String id;
  final String nome;
  final String cultura;
  final double umidadeAtual;
  final double metaUmidade;
  final bool conectado;
  final bool irrigando;
  final ModoIrrigacao modo;
  final int intervaloHoras;
  final int valorSeco;
  final int valorMolhado;

  // Imagem armazenada como arquivo no Android.
  final String? caminhoImagem;

  // Imagem armazenada em Base64 no Chrome.
  final String? imagemBase64;

  Canteiro copiarCom({
    String? nome,
    String? cultura,
    double? umidadeAtual,
    double? metaUmidade,
    bool? conectado,
    bool? irrigando,
    ModoIrrigacao? modo,
    int? intervaloHoras,
    int? valorSeco,
    int? valorMolhado,
    String? caminhoImagem,
    String? imagemBase64,
    bool removerImagem = false,
  }) {
    return Canteiro(
      id: id,
      nome: nome ?? this.nome,
      cultura: cultura ?? this.cultura,
      umidadeAtual: umidadeAtual ?? this.umidadeAtual,
      metaUmidade: metaUmidade ?? this.metaUmidade,
      conectado: conectado ?? this.conectado,
      irrigando: irrigando ?? this.irrigando,
      modo: modo ?? this.modo,
      intervaloHoras: intervaloHoras ?? this.intervaloHoras,
      valorSeco: valorSeco ?? this.valorSeco,
      valorMolhado: valorMolhado ?? this.valorMolhado,
      caminhoImagem: removerImagem ? null : caminhoImagem ?? this.caminhoImagem,
      imagemBase64: removerImagem ? null : imagemBase64 ?? this.imagemBase64,
    );
  }
}

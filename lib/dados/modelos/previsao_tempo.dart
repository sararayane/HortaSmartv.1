class PrevisaoTempo {
  final String cidade;
  final String pais;
  final double temperatura;
  final double umidadeRelativa;
  final double probabilidadeChuva;
  final double velocidadeVento;
  final int codigoClima;
  final DateTime atualizadoEm;

  const PrevisaoTempo({
    required this.cidade,
    required this.pais,
    required this.temperatura,
    required this.umidadeRelativa,
    required this.probabilidadeChuva,
    required this.velocidadeVento,
    required this.codigoClima,
    required this.atualizadoEm,
  });

  String get condicao {
    switch (codigoClima) {
      case 0:
        return 'Céu limpo';
      case 1:
        return 'Predominantemente limpo';
      case 2:
        return 'Parcialmente nublado';
      case 3:
        return 'Nublado';
      case 45:
      case 48:
        return 'Neblina';
      case 51:
      case 53:
      case 55:
        return 'Garoa';
      case 56:
      case 57:
        return 'Garoa congelante';
      case 61:
      case 63:
      case 65:
        return 'Chuva';
      case 66:
      case 67:
        return 'Chuva congelante';
      case 71:
      case 73:
      case 75:
      case 77:
        return 'Neve';
      case 80:
      case 81:
      case 82:
        return 'Pancadas de chuva';
      case 85:
      case 86:
        return 'Pancadas de neve';
      case 95:
      case 96:
      case 99:
        return 'Tempestade';
      default:
        return 'Condição indisponível';
    }
  }
}

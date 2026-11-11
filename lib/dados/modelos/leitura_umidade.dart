import 'package:cloud_firestore/cloud_firestore.dart';

class LeituraUmidade {
  const LeituraUmidade({
    required this.id,
    required this.umidade,
    required this.registradoEm,
    required this.origem,
  });

  final String id;
  final double umidade;
  final DateTime? registradoEm;
  final String origem;

  factory LeituraUmidade.fromMap({
    required String id,
    required Map<String, dynamic> dados,
  }) {
    return LeituraUmidade(
      id: id,
      umidade: _converterDouble(dados['umidade']),
      registradoEm: _converterData(dados['registradoEm']),
      origem: dados['origem']?.toString() ?? 'desconhecida',
    );
  }

  static double _converterDouble(dynamic valor) {
    if (valor is num) return valor.toDouble();
    return double.tryParse(valor?.toString() ?? '') ?? 0;
  }

  static DateTime? _converterData(dynamic valor) {
    if (valor is Timestamp) return valor.toDate();
    if (valor is DateTime) return valor;
    if (valor is String) return DateTime.tryParse(valor);
    return null;
  }
}

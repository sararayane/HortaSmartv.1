import 'package:cloud_firestore/cloud_firestore.dart';

class EventoIrrigacao {
  const EventoIrrigacao({
    required this.id,
    required this.tipo,
    required this.registradoEm,
    required this.modo,
    required this.origem,
    required this.estadoConfirmado,
    this.umidadeNoMomento,
  });

  final String id;
  final String tipo;
  final DateTime? registradoEm;
  final String modo;
  final String origem;
  final bool estadoConfirmado;
  final double? umidadeNoMomento;

  factory EventoIrrigacao.fromMap({
    required String id,
    required Map<String, dynamic> dados,
  }) {
    return EventoIrrigacao(
      id: id,
      tipo: dados['tipo']?.toString() ?? 'evento',
      registradoEm: _converterData(dados['registradoEm']),
      modo: dados['modo']?.toString() ?? 'manual',
      origem: dados['origem']?.toString() ?? 'desconhecida',
      estadoConfirmado: dados['estadoConfirmado'] == true,
      umidadeNoMomento: _converterDoubleOpcional(dados['umidadeNoMomento']),
    );
  }

  static DateTime? _converterData(dynamic valor) {
    if (valor is Timestamp) return valor.toDate();
    if (valor is DateTime) return valor;
    if (valor is String) return DateTime.tryParse(valor);
    return null;
  }

  static double? _converterDoubleOpcional(dynamic valor) {
    if (valor is num) return valor.toDouble();
    return double.tryParse(valor?.toString() ?? '');
  }
}

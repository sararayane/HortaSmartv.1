import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../modelos/evento_irrigacao.dart';
import '../modelos/leitura_umidade.dart';

class RepositorioHistorico {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _autenticacao = FirebaseAuth.instance;

  String get _uid {
    final usuario = _autenticacao.currentUser;

    if (usuario == null) {
      throw StateError(
        'É necessário estar autenticado para acessar o histórico.',
      );
    }

    return usuario.uid;
  }

  DocumentReference<Map<String, dynamic>> _referenciaCanteiro(
    String canteiroId,
  ) {
    return _firestore
        .collection('usuarios')
        .doc(_uid)
        .collection('canteiros')
        .doc(canteiroId);
  }

  CollectionReference<Map<String, dynamic>> _colecaoLeituras(
    String canteiroId,
  ) {
    return _referenciaCanteiro(canteiroId).collection('leituras_umidade');
  }

  CollectionReference<Map<String, dynamic>> _colecaoEventos(String canteiroId) {
    return _referenciaCanteiro(canteiroId).collection('eventos_irrigacao');
  }

  /// Registra uma leitura de umidade.
  ///
  /// Este método será utilizado pela integração com o ESP32.
  /// Não cria leituras fictícias nem altera o valor atual do canteiro.
  Future<void> registrarLeituraUmidade({
    required String canteiroId,
    required double umidade,
    String origem = 'esp32',
  }) async {
    if (!umidade.isFinite || umidade < 0 || umidade > 100) {
      throw ArgumentError('A umidade precisa estar entre 0 e 100.');
    }

    await _colecaoLeituras(canteiroId).add({
      'umidade': umidade,
      'registradoEm': FieldValue.serverTimestamp(),
      'origem': origem,
    });
  }

  /// Acompanha as leituras de um canteiro dentro do período selecionado.
  Stream<List<LeituraUmidade>> acompanharLeiturasUmidade({
    required String canteiroId,
    required int periodoDias,
  }) {
    final inicio = DateTime.now().subtract(Duration(days: periodoDias));

    return _colecaoLeituras(canteiroId)
        .where(
          'registradoEm',
          isGreaterThanOrEqualTo: Timestamp.fromDate(inicio),
        )
        .orderBy('registradoEm')
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((documento) {
                return LeituraUmidade.fromMap(
                  id: documento.id,
                  dados: documento.data(),
                );
              })
              .where((leitura) => leitura.registradoEm != null)
              .toList();
        });
  }

  /// Acompanha os eventos de irrigação do canteiro.
  Stream<List<EventoIrrigacao>> acompanharEventosIrrigacao({
    required String canteiroId,
    required int periodoDias,
  }) {
    final inicio = DateTime.now().subtract(Duration(days: periodoDias));

    return _colecaoEventos(canteiroId)
        .where(
          'registradoEm',
          isGreaterThanOrEqualTo: Timestamp.fromDate(inicio),
        )
        .orderBy('registradoEm', descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((documento) {
                return EventoIrrigacao.fromMap(
                  id: documento.id,
                  dados: documento.data(),
                );
              })
              .where((evento) => evento.registradoEm != null)
              .toList();
        });
  }
}

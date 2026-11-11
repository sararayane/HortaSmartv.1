import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../modelos/canteiro.dart';

/// Repositório responsável por armazenar e consultar os canteiros
/// de cada usuário no Firebase Firestore.
class RepositorioCanteiro {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _autenticacao = FirebaseAuth.instance;

  /// Retorna a coleção de canteiros do usuário autenticado.
  CollectionReference<Map<String, dynamic>> get _colecao {
    final usuario = _autenticacao.currentUser;

    if (usuario == null) {
      throw StateError(
        'É necessário estar autenticado para acessar os canteiros.',
      );
    }

    return _firestore
        .collection('usuarios')
        .doc(usuario.uid)
        .collection('canteiros');
  }

  /// Acompanha os canteiros em tempo real.
  Stream<List<Canteiro>> acompanharCanteiros() {
    return _colecao.snapshots().map((snapshot) {
      return snapshot.docs.map((documento) {
        return Canteiro.fromMap(id: documento.id, dados: documento.data());
      }).toList();
    });
  }

  /// Busca todos os canteiros cadastrados pelo usuário.
  Future<List<Canteiro>> buscarCanteiros() async {
    final snapshot = await _colecao.get();

    return snapshot.docs.map((documento) {
      return Canteiro.fromMap(id: documento.id, dados: documento.data());
    }).toList();
  }

  /// Salva um novo canteiro no Firestore.
  Future<void> salvar(Canteiro canteiro) async {
    await _colecao.doc(canteiro.id).set(canteiro.toMap());
  }

  /// Atualiza um canteiro.
  ///
  /// Quando o campo irrigando muda, registra uma solicitação
  /// de início ou interrupção na subcoleção eventos_irrigacao.
  Future<void> atualizar(Canteiro canteiro) async {
    final referencia = _colecao.doc(canteiro.id);

    final referenciaEvento = referencia.collection('eventos_irrigacao').doc();

    await _firestore.runTransaction((transacao) async {
      final documentoAnterior = await transacao.get(referencia);

      final dadosAnteriores = documentoAnterior.data();

      final estavaIrrigando = dadosAnteriores?['irrigando'] == true;

      transacao.set(referencia, canteiro.toMap(), SetOptions(merge: true));

      final mudouEstado =
          documentoAnterior.exists && estavaIrrigando != canteiro.irrigando;

      if (mudouEstado) {
        transacao.set(referenciaEvento, {
          'tipo':
              canteiro.irrigando ? 'inicio_solicitado' : 'parada_solicitada',
          'registradoEm': FieldValue.serverTimestamp(),
          'modo': canteiro.modo.name,
          'origem': 'aplicativo',
          'estadoConfirmado': false,
          'umidadeNoMomento': canteiro.umidadeAtual,
        });
      }
    });
  }

  /// Exclui um canteiro do Firestore.
  Future<void> excluir(String idCanteiro) async {
    await _colecao.doc(idCanteiro).delete();
  }

  /// Dados locais de demonstração.
  /// Mantidos temporariamente para preservar as telas existentes.
  static List<Canteiro> criarDadosDemonstracao() => const [
    Canteiro(
      id: 'canteiro-01',
      nome: 'Canteiro 1',
      cultura: 'Alface',
      umidadeAtual: 68,
      metaUmidade: 65,
      conectado: true,
      irrigando: false,
      modo: ModoIrrigacao.automatico,
      intervaloHoras: 4,
      valorSeco: 3000,
      valorMolhado: 1400,
    ),
    Canteiro(
      id: 'canteiro-02',
      nome: 'Canteiro 2',
      cultura: 'Tomate',
      umidadeAtual: 42,
      metaUmidade: 55,
      conectado: true,
      irrigando: false,
      modo: ModoIrrigacao.automatico,
      intervaloHoras: 6,
      valorSeco: 3050,
      valorMolhado: 1350,
    ),
  ];
}

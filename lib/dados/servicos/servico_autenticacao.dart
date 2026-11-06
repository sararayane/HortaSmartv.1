import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ServicoAutenticacao {
  final FirebaseAuth _autenticacao = FirebaseAuth.instance;
  final FirebaseFirestore _banco = FirebaseFirestore.instance;

  User? get usuarioAtual => _autenticacao.currentUser;

  Stream<User?> get estadoAutenticacao => _autenticacao.authStateChanges();

  // Cadastro de usuário
  Future<void> cadastrar({
    required String nome,
    required String email,
    required String senha,
  }) async {
    final credencial = await _autenticacao.createUserWithEmailAndPassword(
      email: email.trim(),
      password: senha,
    );

    final usuario = credencial.user;

    if (usuario == null) {
      throw Exception('Não foi possível criar a conta.');
    }

    await usuario.updateDisplayName(nome.trim());

    await usuario.sendEmailVerification();

    // Encerra a sessão até que o usuário confirme o e-mail.
    await _autenticacao.signOut();
  }

  // Login de usuário
  Future<void> entrar({
    required String email,
    required String senha,
  }) async {
    final credencial = await _autenticacao.signInWithEmailAndPassword(
      email: email.trim(),
      password: senha,
    );

    final usuario = credencial.user;

    if (usuario == null) {
      throw Exception('Não foi possível identificar o usuário.');
    }

    // Atualiza os dados de verificação do Firebase.
    await usuario.reload();

    final usuarioAtualizado = _autenticacao.currentUser;

    if (usuarioAtualizado == null || !usuarioAtualizado.emailVerified) {
      await usuarioAtualizado?.sendEmailVerification();

      await _autenticacao.signOut();

      throw FirebaseAuthException(
        code: 'email-nao-verificado',
        message: 'Confirme seu e-mail antes de entrar.',
      );
    }

    // Cria ou atualiza o documento do usuário no Firestore.
    await _criarOuAtualizarUsuario(usuarioAtualizado);
  }

  // Criar ou atualizar o perfil no Firestore
  Future<void> _criarOuAtualizarUsuario(User usuario) async {
    final documento = _banco.collection('usuarios').doc(usuario.uid);

    final consulta = await documento.get();

    final dados = <String, dynamic>{
      'nome': usuario.displayName ?? '',
      'email': usuario.email ?? '',
      'ativo': true,
      'ultimoAcesso': FieldValue.serverTimestamp(),
    };

    if (!consulta.exists) {
      dados['criadoEm'] = FieldValue.serverTimestamp();
    }

    await documento.set(
      dados,
      SetOptions(merge: true),
    );
  }

  // Recuperação de senha
  Future<void> recuperarSenha(String email) async {
    await _autenticacao.sendPasswordResetEmail(
      email: email.trim(),
    );
  }

  // Encerrar sessão
  Future<void> sair() async {
    await _autenticacao.signOut();
  }
}

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';

class ServicoAutenticacao {
  final FirebaseAuth _autenticacao = FirebaseAuth.instance;

  // Inicialização única do Google Sign-In.
  static Future<void>? _inicializacaoGoogle;

  User? get usuarioAtual => _autenticacao.currentUser;

  Stream<User?> get estadoAutenticacao => _autenticacao.authStateChanges();

  // CADASTRO COM E-MAIL E SENHA

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

    await _autenticacao.signOut();
  }

  // LOGIN COM E-MAIL E SENHA

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
  }

  // LOGIN COM GOOGLE

  Future<UserCredential> entrarComGoogle() async {
    // WEB: autenticação diretamente pelo Firebase.

    if (kIsWeb) {
      final provedor = GoogleAuthProvider();

      return await _autenticacao.signInWithPopup(
        provedor,
      );
    }

    // ANDROID E IOS: Google Sign-In nativo.

    _inicializacaoGoogle ??= GoogleSignIn.instance.initialize();

    await _inicializacaoGoogle!;

    if (!GoogleSignIn.instance.supportsAuthenticate()) {
      throw FirebaseAuthException(
        code: 'google-indisponivel',
        message: 'O acesso com Google não está disponível nesta plataforma.',
      );
    }

    final contaGoogle = await GoogleSignIn.instance.authenticate();

    final autenticacaoGoogle = contaGoogle.authentication;

    final idToken = autenticacaoGoogle.idToken;

    if (idToken == null || idToken.isEmpty) {
      throw FirebaseAuthException(
        code: 'google-token-ausente',
        message: 'Não foi possível obter o token do Google.',
      );
    }

    final credencial = GoogleAuthProvider.credential(
      idToken: idToken,
    );

    return await _autenticacao.signInWithCredential(
      credencial,
    );
  }

  // RECUPERAÇÃO DE SENHA

  Future<void> recuperarSenha(String email) async {
    await _autenticacao.sendPasswordResetEmail(
      email: email.trim(),
    );
  }

  // SAIR DA CONTA

  Future<void> sair() async {
    await _autenticacao.signOut();
  }
}

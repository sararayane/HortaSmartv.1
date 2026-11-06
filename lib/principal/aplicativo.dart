import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'tema.dart';
import '../dados/servicos/servico_autenticacao.dart';
import '../funcionalidades/autenticacao/tela_abertura.dart';
import 'tela_principal.dart';

class AplicativoHortasmart extends StatelessWidget {
  const AplicativoHortasmart({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'HortaSmart',
      debugShowCheckedModeBanner: false,
      theme: TemaHortasmart.claro,
      home: StreamBuilder<User?>(
        stream: ServicoAutenticacao().estadoAutenticacao,
        builder: (context, snapshot) {
          // Aguarda o Firebase verificar a sessão.
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(
              body: Center(
                child: CircularProgressIndicator(),
              ),
            );
          }

          final usuario = snapshot.data;

          // Usuário autenticado e com e-mail confirmado.
          if (usuario != null && usuario.emailVerified) {
            return const TelaPrincipal();
          }

          // Usuário não autenticado ou sem e-mail confirmado.
          return const TelaAbertura();
        },
      ),
    );
  }
}

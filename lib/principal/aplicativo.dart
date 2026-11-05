import 'package:flutter/material.dart';
import 'tema.dart';
import 'tela_principal.dart';

class AplicativoHortasmart extends StatelessWidget {
  const AplicativoHortasmart({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'HortaSmart',
      debugShowCheckedModeBanner: false,
      theme: TemaHortasmart.claro,
      home: const TelaPrincipal(),
    );
  }
}

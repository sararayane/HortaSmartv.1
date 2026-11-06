import 'package:flutter/material.dart';

import 'tela_login.dart';
import 'tela_cadastro.dart';

class TelaAbertura extends StatelessWidget {
  const TelaAbertura({super.key});

  static const Color _verde = Color(0xFF087443);
  static const Color _verdeEscuro = Color(0xFF064D31);
  static const Color _fundo = Color(0xFFF5F8F5);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _fundo,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(
              horizontal: 24,
              vertical: 32,
            ),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 460),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      color: _verde.withValues(alpha: 0.10),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.eco_rounded,
                      size: 58,
                      color: _verde,
                    ),
                  ),
                  const SizedBox(height: 28),
                  const Text(
                    'HortaSmart',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 36,
                      fontWeight: FontWeight.bold,
                      color: _verdeEscuro,
                      letterSpacing: -1,
                    ),
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'Tecnologia que cultiva o futuro.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 16,
                      color: Color(0xFF64746A),
                    ),
                  ),
                  const SizedBox(height: 40),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(24),
                    decoration: const BoxDecoration(
                      color: Color(0xFFE1F1E7),
                      borderRadius: BorderRadius.all(
                        Radius.circular(32),
                      ),
                    ),
                    child: const Column(
                      children: [
                        Icon(
                          Icons.energy_savings_leaf_rounded,
                          size: 42,
                          color: _verde,
                        ),
                        SizedBox(height: 16),
                        Text(
                          'Cuide da sua plantação de forma inteligente',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: _verdeEscuro,
                          ),
                        ),
                        SizedBox(height: 12),
                        Text(
                          'Acompanhe a umidade do solo, '
                          'controle a irrigação e utilize a água '
                          'de maneira mais eficiente.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 14,
                            height: 1.5,
                            color: Color(0xFF52665A),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 36),
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _verde,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const TelaLogin(),
                          ),
                        );
                      },
                      child: const Text(
                        'Entrar na minha conta',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: _verde,
                        side: const BorderSide(
                          color: _verde,
                          width: 1.5,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const TelaCadastro(),
                          ),
                        );
                      },
                      child: const Text(
                        'Criar minha conta',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 28),
                  const Text(
                    'HortaSmart • Irrigação inteligente',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 12,
                      color: Color(0xFF849188),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

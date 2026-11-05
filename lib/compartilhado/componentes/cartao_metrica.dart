import 'package:flutter/material.dart';
import '../constantes/cores.dart';

class CartaoMetrica extends StatelessWidget {
  const CartaoMetrica({
    super.key,
    required this.rotulo,
    required this.valor,
    required this.descricao,
    required this.icone,
    this.cor = CoresHortasmart.verde,
    this.fundoIcone = CoresHortasmart.verdeClaro,
  });

  final String rotulo;
  final String valor;
  final String descricao;
  final IconData icone;
  final Color cor;
  final Color fundoIcone;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(18)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(width: 38, height: 38, decoration: BoxDecoration(color: fundoIcone, borderRadius: BorderRadius.circular(12)),
          child: Icon(icone, color: cor, size: 20)),
        const SizedBox(height: 16),
        Text(rotulo, style: const TextStyle(color: CoresHortasmart.textoSecundario, fontSize: 12, fontWeight: FontWeight.w600)),
        const SizedBox(height: 4),
        Text(valor, style: const TextStyle(color: CoresHortasmart.texto, fontSize: 24, fontWeight: FontWeight.w800, letterSpacing: -0.5)),
        const SizedBox(height: 4),
        Text(descricao, style: const TextStyle(color: CoresHortasmart.textoSecundario, fontSize: 11, height: 1.3)),
      ]),
    );
  }
}

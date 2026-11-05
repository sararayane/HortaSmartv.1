import 'package:flutter/material.dart';
import '../../compartilhado/constantes/cores.dart';

class CartaoConsumoAgua extends StatelessWidget {
  const CartaoConsumoAgua({super.key, required this.litrosEstimados, required this.ciclos});
  final int litrosEstimados;
  final int ciclos;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(17),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(18)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(width: 40, height: 40, decoration: BoxDecoration(color: const Color(0xFFE8F2FA), borderRadius: BorderRadius.circular(13)),
          child: const Icon(Icons.water_drop_rounded, color: CoresHortasmart.azul)),
        const SizedBox(height: 14),
        const Text('Água estimada', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: CoresHortasmart.textoSecundario)),
        const SizedBox(height: 3),
        Text('$litrosEstimados L', style: const TextStyle(fontSize: 25, fontWeight: FontWeight.w900, letterSpacing: -0.8, color: CoresHortasmart.texto)),
        const SizedBox(height: 4),
        const Text('Estimativa ilustrativa', style: TextStyle(fontSize: 11, color: CoresHortasmart.textoSecundario)),
        const SizedBox(height: 14),
        const Divider(height: 1, color: Color(0xFFE8EDE6)),
        const SizedBox(height: 11),
        Row(children: [const Icon(Icons.autorenew_rounded, size: 15, color: CoresHortasmart.textoSecundario), const SizedBox(width: 6), Text('$ciclos ciclos de irrigação', style: const TextStyle(fontSize: 11, color: CoresHortasmart.textoSecundario))]),
      ]),
    );
  }
}

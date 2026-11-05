import 'package:flutter/material.dart';
import '../constantes/cores.dart';

class AvisoDemonstracao extends StatelessWidget {
  const AvisoDemonstracao({super.key, this.texto = 'Prévia visual: os dados ainda não vêm do ESP32/Firebase.'});
  final String texto;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(color: const Color(0xFFEAF2F7), borderRadius: BorderRadius.circular(12)),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Icon(Icons.info_outline_rounded, color: CoresHortasmart.azul, size: 18),
        const SizedBox(width: 8),
        Expanded(child: Text(texto, style: const TextStyle(color: CoresHortasmart.azul, fontSize: 12, height: 1.4))),
      ]),
    );
  }
}

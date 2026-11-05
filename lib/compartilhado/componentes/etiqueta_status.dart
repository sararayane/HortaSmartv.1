import 'package:flutter/material.dart';
import '../constantes/cores.dart';

class EtiquetaStatus extends StatelessWidget {
  const EtiquetaStatus({super.key, required this.texto, required this.cor, required this.fundo, this.icone});
  final String texto;
  final Color cor;
  final Color fundo;
  final IconData? icone;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(color: fundo, borderRadius: BorderRadius.circular(99)),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        if (icone != null) ...[Icon(icone, size: 14, color: cor), const SizedBox(width: 5)]
        else ...[Container(width: 7, height: 7, decoration: BoxDecoration(color: cor, shape: BoxShape.circle)), const SizedBox(width: 6)],
        Text(texto, style: TextStyle(color: cor, fontSize: 11, fontWeight: FontWeight.w800)),
      ]),
    );
  }
}

class EtiquetaDemonstracao extends StatelessWidget {
  const EtiquetaDemonstracao({super.key});

  @override
  Widget build(BuildContext context) => const EtiquetaStatus(
    texto: 'DADOS DEMONSTRATIVOS',
    cor: CoresHortasmart.azul,
    fundo: Color(0xFFE8F2FA),
    icone: Icons.science_outlined,
  );
}

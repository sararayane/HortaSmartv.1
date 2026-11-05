import 'package:flutter/material.dart';
import '../constantes/cores.dart';

class CabecalhoPagina extends StatelessWidget {
  const CabecalhoPagina({
    super.key,
    required this.titulo,
    required this.subtitulo,
    this.acao,
  });

  final String titulo;
  final String subtitulo;
  final Widget? acao;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(titulo, style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: CoresHortasmart.texto, fontWeight: FontWeight.w800, letterSpacing: -0.5,
              )),
              const SizedBox(height: 5),
              Text(subtitulo, style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: CoresHortasmart.textoSecundario, height: 1.35,
              )),
            ],
          ),
        ),
        if (acao != null) ...[const SizedBox(width: 12), acao!],
      ],
    );
  }
}

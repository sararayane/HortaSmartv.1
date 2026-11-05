import 'package:flutter/material.dart';
import '../constantes/cores.dart';

class TituloSecao extends StatelessWidget {
  const TituloSecao({super.key, required this.titulo, this.detalhe});
  final String titulo;
  final String? detalhe;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(child: Text(titulo, style: Theme.of(context).textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.w800, color: CoresHortasmart.texto,
        ))),
        if (detalhe != null)
          Text(detalhe!, style: Theme.of(context).textTheme.labelMedium?.copyWith(
            color: CoresHortasmart.textoSecundario,
          )),
      ],
    );
  }
}

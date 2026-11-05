import 'package:flutter/material.dart';
import '../constantes/cores.dart';

class EstadoUmidade {
  const EstadoUmidade(this.texto, this.cor, this.fundo);
  final String texto;
  final Color cor;
  final Color fundo;
}

EstadoUmidade classificarUmidade(double umidade) {
  if (umidade < 30) {
    return const EstadoUmidade('Crítico', CoresHortasmart.vermelho, CoresHortasmart.vermelhoClaro);
  }
  if (umidade < 50) {
    return const EstadoUmidade('Atenção', CoresHortasmart.amarelo, CoresHortasmart.amareloClaro);
  }
  return const EstadoUmidade('Adequada', CoresHortasmart.verde, CoresHortasmart.verdeClaro);
}

class IndicadorUmidade extends StatelessWidget {
  const IndicadorUmidade({super.key, required this.umidade, this.mostrarTexto = true, this.tamanho = 10});
  final double umidade;
  final bool mostrarTexto;
  final double tamanho;

  @override
  Widget build(BuildContext context) {
    final estado = classificarUmidade(umidade);
    return Row(mainAxisSize: MainAxisSize.min, children: [
      Container(width: tamanho, height: tamanho, decoration: BoxDecoration(color: estado.cor, shape: BoxShape.circle)),
      if (mostrarTexto) ...[
        const SizedBox(width: 7),
        Text(estado.texto, style: TextStyle(color: estado.cor, fontSize: 12, fontWeight: FontWeight.w700)),
      ],
    ]);
  }
}

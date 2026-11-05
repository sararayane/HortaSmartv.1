import 'package:flutter/material.dart';
import '../../compartilhado/constantes/cores.dart';

class ControleUmidade extends StatelessWidget {
  const ControleUmidade({super.key, required this.valor, required this.aoAlterar, this.habilitado = true});
  final double valor;
  final ValueChanged<double> aoAlterar;
  final bool habilitado;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(18)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
          const Expanded(child: Text('Meta de umidade', style: TextStyle(color: CoresHortasmart.texto, fontWeight: FontWeight.w800, fontSize: 15))),
          Text('${valor.round()}%', style: const TextStyle(color: CoresHortasmart.verde, fontSize: 30, fontWeight: FontWeight.w900, letterSpacing: -1)),
        ]),
        const SizedBox(height: 5),
        const Text('Defina o objetivo de umidade para este canteiro.', style: TextStyle(color: CoresHortasmart.textoSecundario, fontSize: 12)),
        Slider(value: valor.clamp(0, 100).toDouble(), min: 0, max: 100, divisions: 20, label: '${valor.round()}%', onChanged: habilitado ? aoAlterar : null),
        const Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text('0% · Seco', style: TextStyle(color: CoresHortasmart.textoSecundario, fontSize: 11)),
          Text('100% · Úmido', style: TextStyle(color: CoresHortasmart.textoSecundario, fontSize: 11)),
        ]),
      ]),
    );
  }
}

import 'package:flutter/material.dart';
import '../../dados/modelos/canteiro.dart';
import '../../compartilhado/constantes/cores.dart';

class SeletorModo extends StatelessWidget {
  const SeletorModo({super.key, required this.modo, required this.aoAlterar});
  final ModoIrrigacao modo;
  final ValueChanged<ModoIrrigacao> aoAlterar;

  @override
  Widget build(BuildContext context) {
    return SegmentedButton<ModoIrrigacao>(
      segments: const [
        ButtonSegment(value: ModoIrrigacao.automatico, label: Text('Automático'), icon: Icon(Icons.autorenew_rounded)),
        ButtonSegment(value: ModoIrrigacao.manual, label: Text('Manual'), icon: Icon(Icons.touch_app_outlined)),
      ],
      selected: {modo},
      onSelectionChanged: (selecionados) => aoAlterar(selecionados.first),
      showSelectedIcon: false,
      style: ButtonStyle(
        padding: const WidgetStatePropertyAll(EdgeInsets.symmetric(vertical: 13, horizontal: 8)),
        foregroundColor: WidgetStateProperty.resolveWith((states) => states.contains(WidgetState.selected) ? Colors.white : CoresHortasmart.textoSecundario),
        backgroundColor: WidgetStateProperty.resolveWith((states) => states.contains(WidgetState.selected) ? CoresHortasmart.verde : Colors.white),
      ),
    );
  }
}

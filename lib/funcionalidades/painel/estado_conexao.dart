import 'package:flutter/material.dart';

import '../../compartilhado/constantes/cores.dart';

class EstadoConexao extends StatelessWidget {
  const EstadoConexao({super.key, required this.dispositivosConectados, required this.totalDispositivos});

  final int dispositivosConectados;
  final int totalDispositivos;

  @override
  Widget build(BuildContext context) {
    final todosConectados = totalDispositivos > 0 && dispositivosConectados == totalDispositivos;
    final algumConectado = dispositivosConectados > 0;
    final cor = todosConectados ? CoresHortasmart.verde : algumConectado ? CoresHortasmart.amarelo : CoresHortasmart.vermelho;
    final fundo = todosConectados ? CoresHortasmart.verdeClaro : algumConectado ? CoresHortasmart.amareloClaro : CoresHortasmart.vermelhoClaro;
    final titulo = todosConectados ? 'ESP32 conectado' : algumConectado ? 'Conexão parcial' : 'ESP32 desconectado';
    final detalhe = dispositivosConectados == 0
        ? 'Nenhum dispositivo online'
        : '$dispositivosConectados de $totalDispositivos dispositivos online';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 13),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(18), border: Border.all(color: const Color(0xFFE5ECE6))),
      child: Row(children: [
        Container(width: 43, height: 43, decoration: BoxDecoration(color: fundo, borderRadius: BorderRadius.circular(14)), child: Icon(Icons.wifi_rounded, color: cor, size: 24)),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(titulo, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 13, color: CoresHortasmart.texto)),
          const SizedBox(height: 4),
          Text('$detalhe · última atualização demonstrativa', maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 10, color: CoresHortasmart.textoSecundario, height: 1.3)),
        ])),
        const SizedBox(width: 8),
        Container(width: 10, height: 10, decoration: BoxDecoration(color: cor, shape: BoxShape.circle)),
      ]),
    );
  }
}

import 'package:flutter/material.dart';
import '../../dados/modelos/canteiro.dart';
import '../../compartilhado/constantes/cores.dart';
import '../../compartilhado/componentes/aviso_demonstracao.dart';

class TelaCalibracao extends StatefulWidget {
  const TelaCalibracao({super.key, required this.canteiro, required this.aoSalvar});
  final Canteiro canteiro;
  final ValueChanged<Canteiro> aoSalvar;

  @override
  State<TelaCalibracao> createState() => _TelaCalibracaoState();
}

class _TelaCalibracaoState extends State<TelaCalibracao> {
  late final TextEditingController _controladorSeco;
  late final TextEditingController _controladorMolhado;

  @override
  void initState() {
    super.initState();
    _controladorSeco = TextEditingController(text: widget.canteiro.valorSeco.toString());
    _controladorMolhado = TextEditingController(text: widget.canteiro.valorMolhado.toString());
  }

  @override
  void dispose() {
    _controladorSeco.dispose();
    _controladorMolhado.dispose();
    super.dispose();
  }

  void _salvar() {
    final seco = int.tryParse(_controladorSeco.text.trim());
    final molhado = int.tryParse(_controladorMolhado.text.trim());
    if (seco == null || molhado == null || seco == molhado || seco < 0 || seco > 4095 || molhado < 0 || molhado > 4095) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Digite valores diferentes entre 0 e 4095.')));
      return;
    }
    widget.aoSalvar(widget.canteiro.copiarCom(valorSeco: seco, valorMolhado: molhado));
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Valores salvos nesta prévia.')));
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Calibração do sensor', style: TextStyle(fontWeight: FontWeight.w800))),
      body: SafeArea(child: Center(child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 680), child: ListView(padding: const EdgeInsets.all(20), children: [
        Container(padding: const EdgeInsets.all(18), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)), child: Row(children: [
          Container(width: 48, height: 48, decoration: BoxDecoration(color: CoresHortasmart.verdeClaro, borderRadius: BorderRadius.circular(15)), child: const Icon(Icons.sensors_rounded, color: CoresHortasmart.verde, size: 25)),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(widget.canteiro.nome, style: const TextStyle(color: CoresHortasmart.texto, fontWeight: FontWeight.w800, fontSize: 16)),
            Text('Sensor capacitivo · ${widget.canteiro.cultura}', style: const TextStyle(color: CoresHortasmart.textoSecundario, fontSize: 12)),
          ])),
        ])),
        const SizedBox(height: 16),
        const AvisoDemonstracao(texto: 'Os valores abaixo são exemplos de leitura bruta. Na calibração real, anote a leitura ADC obtida pelo seu próprio sensor.'),
        const SizedBox(height: 20),
        const Text('1. Referência de solo seco', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: CoresHortasmart.texto)),
        const SizedBox(height: 7),
        const Text('Faça a leitura com o sensor em condição seca, conforme o procedimento definido para o seu protótipo.', style: TextStyle(fontSize: 13, height: 1.4, color: CoresHortasmart.textoSecundario)),
        const SizedBox(height: 10),
        TextField(controller: _controladorSeco, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Valor bruto — seco', suffixText: 'ADC', prefixIcon: Icon(Icons.wb_sunny_outlined))),
        const SizedBox(height: 22),
        const Text('2. Referência de solo úmido', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: CoresHortasmart.texto)),
        const SizedBox(height: 7),
        const Text('Faça a leitura em uma referência úmida controlada. Evite mergulhar partes eletrônicas que não sejam à prova d’água.', style: TextStyle(fontSize: 13, height: 1.4, color: CoresHortasmart.textoSecundario)),
        const SizedBox(height: 10),
        TextField(controller: _controladorMolhado, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Valor bruto — úmido', suffixText: 'ADC', prefixIcon: Icon(Icons.water_drop_outlined))),
        const SizedBox(height: 18),
        Container(padding: const EdgeInsets.all(14), decoration: BoxDecoration(color: const Color(0xFFFFF2D5), borderRadius: BorderRadius.circular(14)), child: const Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Icon(Icons.lightbulb_outline, color: CoresHortasmart.amarelo), SizedBox(width: 9),
          Expanded(child: Text('Alguns sensores apresentam leitura maior quando secos e menor quando molhados. O software deve normalizar os dois extremos para uma porcentagem de 0% a 100%.', style: TextStyle(color: CoresHortasmart.texto, fontSize: 12, height: 1.4))),
        ])),
        const SizedBox(height: 22),
        FilledButton.icon(onPressed: _salvar, icon: const Icon(Icons.save_outlined), label: const Text('Salvar calibração')),
      ])))),
    );
  }
}

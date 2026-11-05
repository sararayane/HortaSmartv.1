import 'package:flutter/material.dart';
import '../../dados/modelos/canteiro.dart';
import '../../compartilhado/constantes/cores.dart';

/// Formulário de cadastro exibido em uma janela modal.
class FormularioCanteiro extends StatefulWidget {
  const FormularioCanteiro({super.key});

  @override
  State<FormularioCanteiro> createState() => _FormularioCanteiroState();
}

class _FormularioCanteiroState extends State<FormularioCanteiro> {
  final _chaveFormulario = GlobalKey<FormState>();
  final _controladorNome = TextEditingController();
  final _controladorCultura = TextEditingController();
  String _tipoCultura = 'Alface';

  @override
  void dispose() {
    _controladorNome.dispose();
    _controladorCultura.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Novo canteiro', style: TextStyle(fontWeight: FontWeight.w800)),
      content: SingleChildScrollView(child: Form(key: _chaveFormulario, child: Column(mainAxisSize: MainAxisSize.min, children: [
        TextFormField(
          controller: _controladorNome,
          decoration: const InputDecoration(labelText: 'Nome do canteiro', hintText: 'Ex.: Canteiro 03'),
          validator: (valor) => valor == null || valor.trim().isEmpty ? 'Informe um nome.' : null,
        ),
        const SizedBox(height: 12),
        DropdownButtonFormField<String>(
          value: _tipoCultura,
          decoration: const InputDecoration(labelText: 'Cultura'),
          items: const ['Alface', 'Tomate', 'Manjericão', 'Couve', 'Outra'].map((item) => DropdownMenuItem(value: item, child: Text(item))).toList(),
          onChanged: (valor) => setState(() => _tipoCultura = valor ?? 'Alface'),
        ),
        if (_tipoCultura == 'Outra') ...[
          const SizedBox(height: 12),
          TextFormField(controller: _controladorCultura, decoration: const InputDecoration(labelText: 'Nome da cultura'),
            validator: (valor) => _tipoCultura == 'Outra' && (valor == null || valor.trim().isEmpty) ? 'Informe a cultura.' : null),
        ],
        const SizedBox(height: 10),
        const Text('O sensor e o ESP32 poderão ser associados ao canteiro na etapa de integração.', style: TextStyle(color: CoresHortasmart.textoSecundario, fontSize: 12, height: 1.4)),
      ]))),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
        FilledButton(onPressed: () {
          if (!_chaveFormulario.currentState!.validate()) return;
          final nome = _controladorNome.text.trim();
          final cultura = _tipoCultura == 'Outra' ? _controladorCultura.text.trim() : _tipoCultura;
          Navigator.pop(context, Canteiro(
            id: 'canteiro-${DateTime.now().microsecondsSinceEpoch}',
            nome: nome,
            cultura: cultura,
            umidadeAtual: 0,
            metaUmidade: 65,
            conectado: false,
            irrigando: false,
            modo: ModoIrrigacao.automatico,
            intervaloHoras: 4,
            valorSeco: 3000,
            valorMolhado: 1400,
          ));
        }, child: const Text('Cadastrar')),
      ],
    );
  }
}

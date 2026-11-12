import 'package:flutter/material.dart';

import '../../dados/modelos/canteiro.dart';
import '../../compartilhado/constantes/cores.dart';

/// Formulário utilizado tanto para cadastrar quanto para editar canteiros.
class FormularioCanteiro extends StatefulWidget {
  const FormularioCanteiro({super.key, this.canteiro});

  final Canteiro? canteiro;

  bool get estaEditando => canteiro != null;

  @override
  State<FormularioCanteiro> createState() => _FormularioCanteiroState();
}

class _FormularioCanteiroState extends State<FormularioCanteiro> {
  final _chaveFormulario = GlobalKey<FormState>();
  final _controladorNome = TextEditingController();
  final _controladorCultura = TextEditingController();

  static const List<String> _culturasDisponiveis = [
    'Alface',
    'Tomate',
    'Manjericão',
    'Couve',
    'Outra',
  ];

  String _tipoCultura = 'Alface';

  @override
  void initState() {
    super.initState();

    final canteiro = widget.canteiro;

    if (canteiro == null) return;

    _controladorNome.text = canteiro.nome;

    if (_culturasDisponiveis.contains(canteiro.cultura)) {
      _tipoCultura = canteiro.cultura;
    } else {
      _tipoCultura = 'Outra';
      _controladorCultura.text = canteiro.cultura;
    }
  }

  @override
  void dispose() {
    _controladorNome.dispose();
    _controladorCultura.dispose();
    super.dispose();
  }

  void _salvar() {
    if (!_chaveFormulario.currentState!.validate()) {
      return;
    }

    final nome = _controladorNome.text.trim();

    final cultura =
        _tipoCultura == 'Outra'
            ? _controladorCultura.text.trim()
            : _tipoCultura;

    final original = widget.canteiro;

    final Canteiro resultado;

    if (original == null) {
      resultado = Canteiro(
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
      );
    } else {
      // Mantém as configurações existentes durante a edição.
      resultado = Canteiro(
        id: original.id,
        nome: nome,
        cultura: cultura,
        umidadeAtual: original.umidadeAtual,
        metaUmidade: original.metaUmidade,
        conectado: original.conectado,
        irrigando: original.irrigando,
        modo: original.modo,
        intervaloHoras: original.intervaloHoras,
        valorSeco: original.valorSeco,
        valorMolhado: original.valorMolhado,
        caminhoImagem: original.caminhoImagem,
        imagemBase64: original.imagemBase64,
      );
    }

    Navigator.pop(context, resultado);
  }

  @override
  Widget build(BuildContext context) {
    final titulo = widget.estaEditando ? 'Editar canteiro' : 'Novo canteiro';
    final textoBotao = widget.estaEditando ? 'Salvar alterações' : 'Cadastrar';

    return AlertDialog(
      title: Text(titulo, style: const TextStyle(fontWeight: FontWeight.w800)),
      content: SizedBox(
        width: 390,
        child: SingleChildScrollView(
          child: Form(
            key: _chaveFormulario,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: _controladorNome,
                  textCapitalization: TextCapitalization.words,
                  textInputAction: TextInputAction.next,
                  maxLength: 40,
                  decoration: const InputDecoration(
                    labelText: 'Nome do canteiro',
                    hintText: 'Ex.: Canteiro 03',
                    prefixIcon: Icon(Icons.grass_rounded),
                    counterText: '',
                  ),
                  validator: (valor) {
                    if (valor == null || valor.trim().isEmpty) {
                      return 'Informe um nome.';
                    }

                    if (valor.trim().length < 2) {
                      return 'O nome deve ter pelo menos 2 caracteres.';
                    }

                    return null;
                  },
                ),
                const SizedBox(height: 14),
                DropdownButtonFormField<String>(
                  initialValue: _tipoCultura,
                  isExpanded: true,
                  decoration: const InputDecoration(
                    labelText: 'Cultura',
                    prefixIcon: Icon(Icons.eco_rounded),
                  ),
                  items:
                      _culturasDisponiveis.map((item) {
                        return DropdownMenuItem(value: item, child: Text(item));
                      }).toList(),
                  onChanged: (valor) {
                    setState(() {
                      _tipoCultura = valor ?? 'Alface';
                    });
                  },
                ),
                if (_tipoCultura == 'Outra') ...[
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: _controladorCultura,
                    textCapitalization: TextCapitalization.words,
                    textInputAction: TextInputAction.done,
                    decoration: const InputDecoration(
                      labelText: 'Nome da cultura',
                      hintText: 'Ex.: Morango',
                      prefixIcon: Icon(Icons.local_florist_rounded),
                    ),
                    validator: (valor) {
                      if (_tipoCultura == 'Outra' &&
                          (valor == null || valor.trim().isEmpty)) {
                        return 'Informe o nome da cultura.';
                      }

                      return null;
                    },
                  ),
                ],
                const SizedBox(height: 16),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: CoresHortasmart.verdeClaro,
                    borderRadius: BorderRadius.circular(13),
                  ),
                  child: const Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.info_outline_rounded,
                        color: CoresHortasmart.verde,
                        size: 20,
                      ),
                      SizedBox(width: 9),
                      Expanded(
                        child: Text(
                          'O sensor e o ESP32 poderão ser associados ao '
                          'canteiro durante a configuração da integração.',
                          style: TextStyle(
                            color: CoresHortasmart.textoSecundario,
                            fontSize: 11,
                            height: 1.45,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        FilledButton(onPressed: _salvar, child: Text(textoBotao)),
      ],
    );
  }
}

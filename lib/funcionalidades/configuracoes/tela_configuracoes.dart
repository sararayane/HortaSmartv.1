import 'package:flutter/material.dart';

import '../../compartilhado/componentes/area_pagina.dart';
import '../../compartilhado/componentes/titulo_secao.dart';
import '../../compartilhado/constantes/cores.dart';
import '../../dados/modelos/canteiro.dart';
import 'cartao_perfil.dart';
import 'formulario_canteiro.dart';
import 'tela_calibracao.dart';

class TelaConfiguracoes extends StatefulWidget {
  const TelaConfiguracoes({
    super.key,
    required this.canteiros,
    required this.aoAdicionarCanteiro,
    required this.aoAtualizarCanteiro,
    required this.aoRemoverCanteiro,
  });

  final List<Canteiro> canteiros;
  final ValueChanged<Canteiro> aoAdicionarCanteiro;
  final ValueChanged<Canteiro> aoAtualizarCanteiro;
  final ValueChanged<String> aoRemoverCanteiro;

  @override
  State<TelaConfiguracoes> createState() => _TelaConfiguracoesState();
}

class _TelaConfiguracoesState extends State<TelaConfiguracoes> {
  final GlobalKey _chaveCanteiros = GlobalKey();

  static const List<int> _intervalosDisponiveis = [1, 2, 4, 6, 8, 12, 24];

  Future<void> _abrirFormulario({Canteiro? canteiro}) async {
    final resultado = await showDialog<Canteiro>(
      context: context,
      builder: (_) => FormularioCanteiro(canteiro: canteiro),
    );

    if (!mounted || resultado == null) return;

    if (canteiro == null) {
      widget.aoAdicionarCanteiro(resultado);
      _mensagem('${resultado.nome} foi cadastrado com sucesso.');
    } else {
      widget.aoAtualizarCanteiro(resultado);
      _mensagem('${resultado.nome} foi atualizado com sucesso.');
    }
  }

  Future<void> _calibrar(Canteiro canteiro) async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder:
            (_) => TelaCalibracao(
              canteiro: canteiro,
              aoSalvar: widget.aoAtualizarCanteiro,
            ),
      ),
    );
  }

  Future<void> _selecionarCanteiroParaCalibrar() async {
    if (widget.canteiros.isEmpty) {
      _mensagem('Cadastre um canteiro antes de calibrar um sensor.');
      return;
    }

    final canteiro = await showModalBottomSheet<Canteiro>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder:
          (sheetContext) => SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(sheetContext).size.height * 0.62,
                ),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Padding(
                        padding: EdgeInsets.only(bottom: 12),
                        child: Text(
                          'Qual sensor deseja calibrar?',
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w900,
                            color: CoresHortasmart.texto,
                          ),
                        ),
                      ),
                      ...widget.canteiros.map(
                        (item) => ListTile(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(13),
                          ),
                          leading: const CircleAvatar(
                            backgroundColor: CoresHortasmart.verdeClaro,
                            child: Icon(
                              Icons.sensors_rounded,
                              color: CoresHortasmart.verde,
                            ),
                          ),
                          title: Text(
                            item.cultura,
                            style: const TextStyle(fontWeight: FontWeight.w800),
                          ),
                          subtitle: Text(item.nome),
                          trailing: const Icon(Icons.chevron_right_rounded),
                          onTap: () => Navigator.pop(sheetContext, item),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
    );

    if (canteiro != null && mounted) {
      await _calibrar(canteiro);
    }
  }

  Future<void> _mostrarDispositivos() async {
    final conectados =
        widget.canteiros.where((canteiro) => canteiro.conectado).length;

    final total = widget.canteiros.length;

    await showDialog<void>(
      context: context,
      builder:
          (dialogContext) => AlertDialog(
            icon: const Icon(
              Icons.memory_rounded,
              color: CoresHortasmart.verde,
              size: 30,
            ),
            title: const Text('Dispositivo ESP32'),
            content: ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: 390,
                maxHeight: MediaQuery.of(dialogContext).size.height * 0.65,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(13),
                      decoration: BoxDecoration(
                        color: CoresHortasmart.verdeClaro,
                        borderRadius: BorderRadius.circular(13),
                      ),
                      child: const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.developer_board_rounded,
                                color: CoresHortasmart.verde,
                              ),
                              SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Central de controle',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w900,
                                    color: CoresHortasmart.texto,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 7),
                          Text(
                            'Um ESP32 poderá controlar os dois canteiros, '
                            'acionando cada válvula de forma independente.',
                            style: TextStyle(
                              fontSize: 11,
                              height: 1.45,
                              color: CoresHortasmart.textoSecundario,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Canteiros associados: $conectados de $total com conexão registrada',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 8),
                    if (widget.canteiros.isEmpty)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 12),
                        child: Text(
                          'Nenhum canteiro cadastrado.',
                          style: TextStyle(fontSize: 12),
                        ),
                      )
                    else
                      ...widget.canteiros.map(
                        (canteiro) => ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: Icon(
                            canteiro.conectado
                                ? Icons.wifi_rounded
                                : Icons.wifi_off_rounded,
                            color:
                                canteiro.conectado
                                    ? CoresHortasmart.verde
                                    : CoresHortasmart.vermelho,
                          ),
                          title: Text(
                            canteiro.nome,
                            style: const TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 13,
                            ),
                          ),
                          subtitle: Text(
                            canteiro.conectado
                                ? 'Conexão registrada'
                                : 'Sem conexão registrada',
                            style: const TextStyle(fontSize: 11),
                          ),
                          trailing: Container(
                            width: 9,
                            height: 9,
                            decoration: BoxDecoration(
                              color:
                                  canteiro.conectado
                                      ? CoresHortasmart.verde
                                      : CoresHortasmart.vermelho,
                              shape: BoxShape.circle,
                            ),
                          ),
                        ),
                      ),
                    const SizedBox(height: 8),
                    const Text(
                      'A comunicação em tempo real dependerá da integração '
                      'do ESP32 com o Firebase.',
                      style: TextStyle(
                        fontSize: 11,
                        height: 1.4,
                        color: CoresHortasmart.textoSecundario,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext),
                child: const Text('Fechar'),
              ),
            ],
          ),
    );
  }

  Future<void> _editarMetas({String? idInicial}) async {
    if (widget.canteiros.isEmpty) {
      _mensagem('Cadastre um canteiro antes de definir uma meta.');
      return;
    }

    final inicial = widget.canteiros.firstWhere(
      (item) => item.id == idInicial,
      orElse: () => widget.canteiros.first,
    );

    var idSelecionado = inicial.id;
    var meta = inicial.metaUmidade;

    await showDialog<void>(
      context: context,
      builder:
          (dialogContext) => StatefulBuilder(
            builder: (contextInterno, setDialogState) {
              final selecionado = widget.canteiros.firstWhere(
                (item) => item.id == idSelecionado,
                orElse: () => widget.canteiros.first,
              );

              return AlertDialog(
                title: const Text('Meta de umidade'),
                content: SizedBox(
                  width: 360,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'A meta de umidade é individual para cada plantação.',
                        style: TextStyle(
                          fontSize: 12,
                          color: CoresHortasmart.textoSecundario,
                        ),
                      ),
                      const SizedBox(height: 15),
                      DropdownButtonFormField<String>(
                        initialValue: idSelecionado,
                        isExpanded: true,
                        decoration: const InputDecoration(
                          labelText: 'Canteiro',
                        ),
                        items:
                            widget.canteiros.map((item) {
                              return DropdownMenuItem(
                                value: item.id,
                                child: Text(
                                  '${item.cultura} · ${item.nome}',
                                  overflow: TextOverflow.ellipsis,
                                ),
                              );
                            }).toList(),
                        onChanged: (id) {
                          if (id == null) return;

                          final item = widget.canteiros.firstWhere(
                            (canteiro) => canteiro.id == id,
                          );

                          setDialogState(() {
                            idSelecionado = id;
                            meta = item.metaUmidade;
                          });
                        },
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          const Expanded(
                            child: Text(
                              'Meta desejada',
                              style: TextStyle(fontWeight: FontWeight.w800),
                            ),
                          ),
                          Text(
                            '${meta.round()}%',
                            style: const TextStyle(
                              fontWeight: FontWeight.w900,
                              fontSize: 22,
                              color: CoresHortasmart.verde,
                            ),
                          ),
                        ],
                      ),
                      Slider(
                        value: meta.clamp(0, 100).toDouble(),
                        min: 0,
                        max: 100,
                        divisions: 20,
                        label: '${meta.round()}%',
                        onChanged: (valor) {
                          setDialogState(() => meta = valor);
                        },
                      ),
                    ],
                  ),
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(dialogContext),
                    child: const Text('Cancelar'),
                  ),
                  FilledButton(
                    onPressed: () {
                      widget.aoAtualizarCanteiro(
                        selecionado.copiarCom(metaUmidade: meta),
                      );

                      Navigator.pop(dialogContext);
                      _mensagem('Meta de umidade atualizada.');
                    },
                    child: const Text('Salvar meta'),
                  ),
                ],
              );
            },
          ),
    );
  }

  Future<void> _editarProgramacao() async {
    if (widget.canteiros.isEmpty) {
      _mensagem('Cadastre um canteiro antes de configurar a programação.');
      return;
    }

    final inicial = widget.canteiros.first;

    var idSelecionado = inicial.id;
    var intervalo =
        _intervalosDisponiveis.contains(inicial.intervaloHoras)
            ? inicial.intervaloHoras
            : 4;

    await showDialog<void>(
      context: context,
      builder:
          (dialogContext) => StatefulBuilder(
            builder: (contextInterno, setDialogState) {
              final selecionado = widget.canteiros.firstWhere(
                (item) => item.id == idSelecionado,
                orElse: () => widget.canteiros.first,
              );

              return AlertDialog(
                title: const Text('Horários e programação'),
                content: SizedBox(
                  width: 360,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Defina o intervalo de verificação da irrigação automática.',
                        style: TextStyle(
                          fontSize: 12,
                          height: 1.4,
                          color: CoresHortasmart.textoSecundario,
                        ),
                      ),
                      const SizedBox(height: 15),
                      DropdownButtonFormField<String>(
                        initialValue: idSelecionado,
                        isExpanded: true,
                        decoration: const InputDecoration(
                          labelText: 'Canteiro',
                        ),
                        items:
                            widget.canteiros.map((item) {
                              return DropdownMenuItem(
                                value: item.id,
                                child: Text(
                                  '${item.cultura} · ${item.nome}',
                                  overflow: TextOverflow.ellipsis,
                                ),
                              );
                            }).toList(),
                        onChanged: (id) {
                          if (id == null) return;

                          final item = widget.canteiros.firstWhere(
                            (canteiro) => canteiro.id == id,
                          );

                          setDialogState(() {
                            idSelecionado = id;
                            intervalo =
                                _intervalosDisponiveis.contains(
                                      item.intervaloHoras,
                                    )
                                    ? item.intervaloHoras
                                    : 4;
                          });
                        },
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<int>(
                        initialValue: intervalo,
                        isExpanded: true,
                        decoration: const InputDecoration(
                          labelText: 'Verificar a cada',
                        ),
                        items:
                            _intervalosDisponiveis.map((horas) {
                              return DropdownMenuItem(
                                value: horas,
                                child: Text(
                                  '$horas ${horas == 1 ? 'hora' : 'horas'}',
                                ),
                              );
                            }).toList(),
                        onChanged: (valor) {
                          if (valor != null) {
                            setDialogState(() => intervalo = valor);
                          }
                        },
                      ),
                    ],
                  ),
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(dialogContext),
                    child: const Text('Cancelar'),
                  ),
                  FilledButton(
                    onPressed: () {
                      widget.aoAtualizarCanteiro(
                        selecionado.copiarCom(intervaloHoras: intervalo),
                      );

                      Navigator.pop(dialogContext);
                      _mensagem('Programação atualizada.');
                    },
                    child: const Text('Salvar'),
                  ),
                ],
              );
            },
          ),
    );
  }

  Future<void> _confirmarRemocao(Canteiro canteiro) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder:
          (dialogContext) => AlertDialog(
            icon: const Icon(
              Icons.delete_outline_rounded,
              color: CoresHortasmart.vermelho,
              size: 30,
            ),
            title: const Text('Remover canteiro?'),
            content: Text(
              'Deseja realmente remover "${canteiro.nome}"? '
              'Essa ação não poderá ser desfeita.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext, false),
                child: const Text('Cancelar'),
              ),
              FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: CoresHortasmart.vermelho,
                ),
                onPressed: () => Navigator.pop(dialogContext, true),
                child: const Text('Remover'),
              ),
            ],
          ),
    );

    if (confirmar == true && mounted) {
      widget.aoRemoverCanteiro(canteiro.id);
      _mensagem('${canteiro.nome} foi removido.');
    }
  }

  void _rolarParaCanteiros() {
    final contexto = _chaveCanteiros.currentContext;

    if (contexto != null) {
      Scrollable.ensureVisible(
        contexto,
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeInOut,
      );
    }
  }

  void _mensagem(String mensagem) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(mensagem), behavior: SnackBarBehavior.floating),
    );
  }

  @override
  Widget build(BuildContext context) {
    final conectados =
        widget.canteiros.where((canteiro) => canteiro.conectado).length;

    final atalhos = <_AtalhoConfiguracao>[
      _AtalhoConfiguracao(
        Icons.grass_rounded,
        'Gerenciar canteiros',
        'Cadastrar, editar e remover plantações',
        _rolarParaCanteiros,
      ),
      _AtalhoConfiguracao(
        Icons.memory_rounded,
        'Dispositivo ESP32',
        'Visualizar as associações e conexões',
        _mostrarDispositivos,
      ),
      _AtalhoConfiguracao(
        Icons.sensors_rounded,
        'Calibração dos sensores',
        'Configurar referências de leitura',
        _selecionarCanteiroParaCalibrar,
      ),
      _AtalhoConfiguracao(
        Icons.track_changes_rounded,
        'Meta de umidade',
        'Definir uma meta para cada plantação',
        () => _editarMetas(),
      ),
      _AtalhoConfiguracao(
        Icons.schedule_rounded,
        'Horários e programação',
        'Configurar o intervalo automático',
        _editarProgramacao,
      ),
    ];

    return AreaPagina(
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 13),

            Container(
              padding: const EdgeInsets.all(17),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFF087B4B), Color(0xFF075C39)],
                ),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.14),
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: const Icon(
                      Icons.settings_suggest_rounded,
                      color: Colors.white,
                      size: 26,
                    ),
                  ),
                  const SizedBox(width: 13),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Central de configurações',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w900,
                            fontSize: 15,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '$conectados conexões registradas · '
                          '${widget.canteiros.length} canteiros cadastrados',
                          style: const TextStyle(
                            color: Color(0xFFD6F0E1),
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Icon(Icons.tune_rounded, color: Colors.white, size: 25),
                ],
              ),
            ),

            const SizedBox(height: 20),
            const CartaoPerfil(),

            const SizedBox(height: 22),
            const TituloSecao(titulo: 'Configurações do sistema'),
            const SizedBox(height: 11),

            LayoutBuilder(
              builder: (context, constraints) {
                final colunas = constraints.maxWidth >= 760 ? 2 : 1;

                final largura =
                    (constraints.maxWidth - (colunas - 1) * 10) / colunas;

                return Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children:
                      atalhos.map((atalho) {
                        return SizedBox(
                          width: largura,
                          child: _CartaoAtalho(atalho: atalho),
                        );
                      }).toList(),
                );
              },
            ),

            const SizedBox(height: 23),

            Row(
              key: _chaveCanteiros,
              children: [
                const Expanded(
                  child: TituloSecao(titulo: 'Canteiros cadastrados'),
                ),
                FilledButton.icon(
                  onPressed: () => _abrirFormulario(),
                  icon: const Icon(Icons.add_rounded, size: 18),
                  label: const Text('Novo canteiro'),
                ),
              ],
            ),

            const SizedBox(height: 11),

            if (widget.canteiros.isEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(22),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: const Color(0xFFE5ECE6)),
                ),
                child: const Column(
                  children: [
                    Icon(
                      Icons.grass_outlined,
                      size: 34,
                      color: CoresHortasmart.textoSecundario,
                    ),
                    SizedBox(height: 10),
                    Text(
                      'Nenhum canteiro cadastrado.',
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        color: CoresHortasmart.texto,
                      ),
                    ),
                    SizedBox(height: 5),
                    Text(
                      'Use o botão "Novo canteiro" para adicionar sua primeira plantação.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 11,
                        height: 1.4,
                        color: CoresHortasmart.textoSecundario,
                      ),
                    ),
                  ],
                ),
              )
            else
              ...widget.canteiros.map(
                (canteiro) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: _CartaoCanteiroConfiguracao(
                    canteiro: canteiro,
                    aoCalibrar: () => _calibrar(canteiro),
                    aoEditar: () => _abrirFormulario(canteiro: canteiro),
                    aoRemover: () => _confirmarRemocao(canteiro),
                    aoEditarMeta: () => _editarMetas(idInicial: canteiro.id),
                  ),
                ),
              ),

            const SizedBox(height: 12),

            Container(
              padding: const EdgeInsets.all(15),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(17),
                border: Border.all(color: const Color(0xFFE6ECE7)),
              ),
              child: const Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.lightbulb_outline_rounded,
                    color: CoresHortasmart.verde,
                    size: 21,
                  ),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Cada sensor deve ser calibrado individualmente. '
                      'Registre as leituras brutas de referência seca e úmida '
                      'do próprio sensor, pois os valores podem variar entre módulos.',
                      style: TextStyle(
                        fontSize: 11,
                        height: 1.45,
                        color: CoresHortasmart.textoSecundario,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

class _AtalhoConfiguracao {
  const _AtalhoConfiguracao(
    this.icone,
    this.titulo,
    this.subtitulo,
    this.aoTocar,
  );

  final IconData icone;
  final String titulo;
  final String subtitulo;
  final VoidCallback aoTocar;
}

class _CartaoAtalho extends StatelessWidget {
  const _CartaoAtalho({required this.atalho});

  final _AtalhoConfiguracao atalho;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(17),
      child: InkWell(
        onTap: atalho.aoTocar,
        borderRadius: BorderRadius.circular(17),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 13),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(17),
            border: Border.all(color: const Color(0xFFE5ECE6)),
          ),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: CoresHortasmart.verdeClaro,
                  borderRadius: BorderRadius.circular(13),
                ),
                child: Icon(
                  atalho.icone,
                  color: CoresHortasmart.verde,
                  size: 23,
                ),
              ),
              const SizedBox(width: 11),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      atalho.titulo,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w900,
                        color: CoresHortasmart.texto,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      atalho.subtitulo,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 10,
                        height: 1.3,
                        color: CoresHortasmart.textoSecundario,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 6),
              const Icon(
                Icons.chevron_right_rounded,
                color: CoresHortasmart.textoSecundario,
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CartaoCanteiroConfiguracao extends StatelessWidget {
  const _CartaoCanteiroConfiguracao({
    required this.canteiro,
    required this.aoCalibrar,
    required this.aoEditar,
    required this.aoRemover,
    required this.aoEditarMeta,
  });

  final Canteiro canteiro;
  final VoidCallback aoCalibrar;
  final VoidCallback aoEditar;
  final VoidCallback aoRemover;
  final VoidCallback aoEditarMeta;

  String get _emoji {
    switch (canteiro.cultura.toLowerCase()) {
      case 'alface':
        return '🥬';
      case 'tomate':
        return '🍅';
      case 'cenoura':
        return '🥕';
      case 'rúcula':
      case 'rucula':
        return '🌿';
      default:
        return '🌱';
    }
  }

  Color get _corUmidade {
    if (canteiro.umidadeAtual < 30) {
      return CoresHortasmart.vermelho;
    }

    if (canteiro.umidadeAtual < canteiro.metaUmidade) {
      return const Color(0xFFE5A000);
    }

    return CoresHortasmart.verde;
  }

  String get _textoUmidade {
    if (canteiro.umidadeAtual < 30) {
      return 'Crítico';
    }

    if (canteiro.umidadeAtual < canteiro.metaUmidade) {
      return 'Abaixo da meta';
    }

    return 'Adequado';
  }

  @override
  Widget build(BuildContext context) {
    final corUmidade = _corUmidade;

    final corConexao =
        canteiro.conectado ? CoresHortasmart.verde : CoresHortasmart.vermelho;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE5ECE6)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 47,
                height: 47,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: CoresHortasmart.verdeClaro,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Text(_emoji, style: const TextStyle(fontSize: 25)),
              ),
              const SizedBox(width: 11),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      canteiro.nome,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w900,
                        color: CoresHortasmart.texto,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      canteiro.cultura,
                      style: const TextStyle(
                        fontSize: 11,
                        color: CoresHortasmart.textoSecundario,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Meta de umidade: ${canteiro.metaUmidade.round()}%',
                      style: const TextStyle(
                        fontSize: 10,
                        color: CoresHortasmart.textoSecundario,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Container(
                    width: 9,
                    height: 9,
                    decoration: BoxDecoration(
                      color: corConexao,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    canteiro.conectado ? 'Conectado' : 'Desconectado',
                    style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.w700,
                      color: corConexao,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: corUmidade.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                Icon(Icons.water_drop_rounded, color: corUmidade, size: 16),
                const SizedBox(width: 7),
                Expanded(
                  child: Text(
                    'Umidade atual: ${canteiro.umidadeAtual.round()}%',
                    style: TextStyle(
                      color: corUmidade,
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                Text(
                  _textoUmidade,
                  style: TextStyle(
                    color: corUmidade,
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              OutlinedButton.icon(
                onPressed: aoCalibrar,
                icon: const Icon(Icons.tune_rounded, size: 16),
                label: const Text('Calibrar'),
              ),
              OutlinedButton.icon(
                onPressed: aoEditarMeta,
                icon: const Icon(Icons.track_changes_rounded, size: 16),
                label: const Text('Meta'),
              ),
              OutlinedButton.icon(
                onPressed: aoEditar,
                icon: const Icon(Icons.edit_outlined, size: 16),
                label: const Text('Editar'),
              ),
              IconButton(
                onPressed: aoRemover,
                tooltip: 'Remover canteiro',
                style: IconButton.styleFrom(
                  backgroundColor: const Color(0xFFFFEFEE),
                  foregroundColor: CoresHortasmart.vermelho,
                ),
                icon: const Icon(Icons.delete_outline_rounded),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

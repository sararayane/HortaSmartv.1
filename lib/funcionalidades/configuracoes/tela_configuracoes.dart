import 'package:flutter/material.dart';

import '../../compartilhado/componentes/area_pagina.dart';
import '../../compartilhado/componentes/aviso_demonstracao.dart';
import '../../compartilhado/componentes/indicador_umidade.dart';
import '../../compartilhado/componentes/titulo_secao.dart';
import '../../compartilhado/constantes/cores.dart';
import '../../dados/modelos/canteiro.dart';
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

  Future<void> _novoCanteiro(BuildContext context) async {
    final novo = await showDialog<Canteiro>(
        context: context, builder: (_) => const FormularioCanteiro());
    if (novo == null || !context.mounted) return;
    widget.aoAdicionarCanteiro(novo);
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('${novo.nome} foi adicionado à prévia.'),
        behavior: SnackBarBehavior.floating));
  }

  Future<void> _calibrar(BuildContext context, Canteiro canteiro) async {
    await Navigator.of(context).push(MaterialPageRoute<void>(
      builder: (_) => TelaCalibracao(
          canteiro: canteiro, aoSalvar: widget.aoAtualizarCanteiro),
    ));
  }

  Future<void> _selecionarCanteiroParaCalibrar(BuildContext context) async {
    if (widget.canteiros.isEmpty) {
      _mensagem(context, 'Cadastre um canteiro antes de calibrar um sensor.');
      return;
    }
    final canteiro = await showModalBottomSheet<Canteiro>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
          child: ConstrainedBox(
            constraints: BoxConstraints(
                maxHeight: MediaQuery.of(sheetContext).size.height * 0.62),
            child: SingleChildScrollView(
              child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Padding(
                        padding: EdgeInsets.only(bottom: 12),
                        child: Text('Qual sensor deseja calibrar?',
                            style: TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.w900,
                                color: CoresHortasmart.texto))),
                    ...widget.canteiros.map((item) => ListTile(
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(13)),
                          leading: const CircleAvatar(
                              backgroundColor: CoresHortasmart.verdeClaro,
                              child: Icon(Icons.sensors_rounded,
                                  color: CoresHortasmart.verde)),
                          title: Text(item.cultura,
                              style:
                                  const TextStyle(fontWeight: FontWeight.w800)),
                          subtitle: Text(
                              '${item.nome} · Sensor ${item.id.split('-').last.toUpperCase()}'),
                          trailing: const Icon(Icons.chevron_right_rounded),
                          onTap: () => Navigator.pop(sheetContext, item),
                        )),
                  ]),
            ),
          ),
        ),
      ),
    );
    if (canteiro != null && context.mounted) await _calibrar(context, canteiro);
  }

  Future<void> _mostrarDispositivos(BuildContext context) async {
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        icon: const Icon(Icons.memory_rounded,
            color: CoresHortasmart.verde, size: 30),
        title: const Text('Dispositivos ESP32'),
        content: ConstrainedBox(
          constraints: BoxConstraints(
              maxWidth: 390,
              maxHeight: MediaQuery.of(dialogContext).size.height * 0.62),
          child: SingleChildScrollView(
            child: widget.canteiros.isEmpty
                ? const Text('Nenhum dispositivo associado a um canteiro.')
                : Column(
                    mainAxisSize: MainAxisSize.min,
                    children: widget.canteiros
                        .map((canteiro) => ListTile(
                              contentPadding: EdgeInsets.zero,
                              leading: Icon(
                                  canteiro.conectado
                                      ? Icons.wifi_rounded
                                      : Icons.wifi_off_rounded,
                                  color: canteiro.conectado
                                      ? CoresHortasmart.verde
                                      : CoresHortasmart.vermelho),
                              title: Text(
                                  'ESP32 · ${canteiro.id.split('-').last.toUpperCase()}',
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w800,
                                      fontSize: 13)),
                              subtitle: Text(
                                  '${canteiro.nome} · ${canteiro.cultura}',
                                  style: const TextStyle(fontSize: 11)),
                              trailing: Container(
                                  width: 8,
                                  height: 8,
                                  decoration: BoxDecoration(
                                      color: canteiro.conectado
                                          ? CoresHortasmart.verde
                                          : CoresHortasmart.vermelho,
                                      shape: BoxShape.circle)),
                            ))
                        .toList()),
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Fechar'))
        ],
      ),
    );
  }

  Future<void> _editarMetas(BuildContext contextoPai,
      {String? idInicial}) async {
    if (widget.canteiros.isEmpty) {
      _mensagem(contextoPai, 'Cadastre um canteiro antes de definir uma meta.');
      return;
    }
    var inicial = widget.canteiros.first;
    for (final item in widget.canteiros) {
      if (item.id == idInicial) {
        inicial = item;
        break;
      }
    }
    var idSelecionado = inicial.id;
    var meta = inicial.metaUmidade;
    await showDialog<void>(
      context: contextoPai,
      builder: (dialogContext) => StatefulBuilder(
        builder: (contextInterno, setDialogState) {
          Canteiro selecionado = widget.canteiros.first;
          for (final item in widget.canteiros) {
            if (item.id == idSelecionado) {
              selecionado = item;
              break;
            }
          }
          return AlertDialog(
            title: const Text('Meta de umidade'),
            content: SizedBox(
              child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('A meta é individual para cada plantação.',
                        style: TextStyle(
                            fontSize: 12,
                            color: CoresHortasmart.textoSecundario)),
                    const SizedBox(height: 15),
                    DropdownButtonFormField<String>(
                      value: idSelecionado,
                      isExpanded: true,
                      decoration: const InputDecoration(labelText: 'Canteiro'),
                      items: widget.canteiros
                          .map((item) => DropdownMenuItem(
                              value: item.id,
                              child: Text('${item.cultura} · ${item.nome}',
                                  overflow: TextOverflow.ellipsis)))
                          .toList(),
                      onChanged: (id) {
                        if (id == null) return;
                        Canteiro? item;
                        for (final canteiro in widget.canteiros) {
                          if (canteiro.id == id) {
                            item = canteiro;
                            break;
                          }
                        }
                        setDialogState(() {
                          idSelecionado = id;
                          meta = item?.metaUmidade ?? 65;
                        });
                      },
                    ),
                    const SizedBox(height: 16),
                    Row(children: [
                      const Expanded(
                          child: Text('Meta desejada',
                              style: TextStyle(fontWeight: FontWeight.w800))),
                      Text('${meta.round()}%',
                          style: const TextStyle(
                              fontWeight: FontWeight.w900,
                              fontSize: 22,
                              color: CoresHortasmart.verde))
                    ]),
                    Slider(
                        value: meta.clamp(0, 100).toDouble(),
                        min: 0,
                        max: 100,
                        divisions: 20,
                        label: '${meta.round()}%',
                        onChanged: (valor) =>
                            setDialogState(() => meta = valor)),
                  ]),
            ),
            actions: [
              TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: const Text('Cancelar')),
              FilledButton(
                  onPressed: () {
                    widget.aoAtualizarCanteiro(
                        selecionado.copiarCom(metaUmidade: meta));
                    Navigator.pop(dialogContext);
                    _mensagem(contextoPai, 'Meta salva nesta prévia.');
                  },
                  child: const Text('Salvar meta')),
            ],
          );
        },
      ),
    );
  }

  Future<void> _editarProgramacao(BuildContext contextoPai) async {
    if (widget.canteiros.isEmpty) {
      _mensagem(contextoPai,
          'Cadastre um canteiro antes de configurar a programação.');
      return;
    }
    var idSelecionado = widget.canteiros.first.id;
    var intervalo = widget.canteiros.first.intervaloHoras;
    await showDialog<void>(
      context: contextoPai,
      builder: (dialogContext) => StatefulBuilder(
        builder: (contextInterno, setDialogState) {
          Canteiro selecionado = widget.canteiros.first;
          for (final item in widget.canteiros) {
            if (item.id == idSelecionado) {
              selecionado = item;
              break;
            }
          }
          return AlertDialog(
            title: const Text('Horários e programação'),
            content: SizedBox(
              child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                        'Defina com que intervalo o ESP32 deve reavaliar a irrigação automática.',
                        style: TextStyle(
                            fontSize: 12,
                            height: 1.4,
                            color: CoresHortasmart.textoSecundario)),
                    const SizedBox(height: 15),
                    DropdownButtonFormField<String>(
                      value: idSelecionado,
                      isExpanded: true,
                      decoration: const InputDecoration(labelText: 'Canteiro'),
                      items: widget.canteiros
                          .map((item) => DropdownMenuItem(
                              value: item.id,
                              child: Text('${item.cultura} · ${item.nome}',
                                  overflow: TextOverflow.ellipsis)))
                          .toList(),
                      onChanged: (id) {
                        if (id == null) return;
                        Canteiro? item;
                        for (final canteiro in widget.canteiros) {
                          if (canteiro.id == id) {
                            item = canteiro;
                            break;
                          }
                        }
                        setDialogState(() {
                          idSelecionado = id;
                          intervalo = item?.intervaloHoras ?? 4;
                        });
                      },
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<int>(
                      value: intervalo,
                      decoration:
                          const InputDecoration(labelText: 'Verificar a cada'),
                      items: const [1, 2, 4, 6, 8, 12, 24]
                          .map((h) => DropdownMenuItem(
                              value: h,
                              child: Text('$h ${h == 1 ? 'hora' : 'horas'}')))
                          .toList(),
                      onChanged: (valor) {
                        if (valor != null)
                          setDialogState(() => intervalo = valor);
                      },
                    ),
                  ]),
            ),
            actions: [
              TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: const Text('Cancelar')),
              FilledButton(
                  onPressed: () {
                    widget.aoAtualizarCanteiro(
                        selecionado.copiarCom(intervaloHoras: intervalo));
                    Navigator.pop(dialogContext);
                    _mensagem(contextoPai, 'Programação salva nesta prévia.');
                  },
                  child: const Text('Salvar')),
            ],
          );
        },
      ),
    );
  }

  Future<void> _confirmarRemocao(
      BuildContext context, Canteiro canteiro) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Remover canteiro?'),
        content: Text('Deseja remover ${canteiro.nome} desta prévia?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Cancelar')),
          FilledButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text('Remover')),
        ],
      ),
    );
    if (confirmar == true) widget.aoRemoverCanteiro(canteiro.id);
  }

  void _rolarParaCanteiros() {
    final context = _chaveCanteiros.currentContext;
    if (context != null)
      Scrollable.ensureVisible(context,
          duration: const Duration(milliseconds: 350), curve: Curves.easeInOut);
  }

  void _mensagem(BuildContext context, String mensagem) {
    ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(mensagem), behavior: SnackBarBehavior.floating));
  }

  @override
  Widget build(BuildContext context) {
    final conectados =
        widget.canteiros.where((canteiro) => canteiro.conectado).length;
    final atalhos = <_AtalhoConfiguracao>[
      _AtalhoConfiguracao(Icons.grass_rounded, 'Gerenciar canteiros',
          'Cadastrar, editar e remover canteiros', _rolarParaCanteiros),
      _AtalhoConfiguracao(
          Icons.memory_rounded,
          'Dispositivos ESP32',
          'Gerenciar e associar dispositivos',
          () => _mostrarDispositivos(context)),
      _AtalhoConfiguracao(
          Icons.sensors_rounded,
          'Calibração do sensor',
          'Configurar referências de leitura',
          () => _selecionarCanteiroParaCalibrar(context)),
      _AtalhoConfiguracao(Icons.track_changes_rounded, 'Meta de umidade',
          'Definir uma meta por plantação', () => _editarMetas(context)),
      _AtalhoConfiguracao(
          Icons.schedule_rounded,
          'Horários e programação',
          'Configurar o intervalo automático',
          () => _editarProgramacao(context)),
    ];

    return AreaPagina(
      child: SingleChildScrollView(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const AvisoDemonstracao(
              texto:
                  'Alterações ficam salvas somente enquanto esta prévia está aberta. O Firebase será integrado depois.'),
          const SizedBox(height: 13),
          Container(
            padding: const EdgeInsets.all(17),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFF087B4B), Color(0xFF075C39)]),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(children: [
              Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.14),
                      borderRadius: BorderRadius.circular(15)),
                  child: const Icon(Icons.memory_rounded,
                      color: Colors.white, size: 26)),
              const SizedBox(width: 13),
              Expanded(
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                    const Text('Central de dispositivos',
                        style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w900,
                            fontSize: 15)),
                    const SizedBox(height: 4),
                    Text(
                        '$conectados conectados · ${widget.canteiros.length} canteiros cadastrados',
                        style: const TextStyle(
                            color: Color(0xFFD6F0E1), fontSize: 11)),
                  ])),
              const Icon(Icons.wifi_rounded, color: Colors.white, size: 26),
            ]),
          ),
          const SizedBox(height: 22),
          const TituloSecao(titulo: 'Configurações do sistema'),
          const SizedBox(height: 11),
          LayoutBuilder(builder: (context, constraints) {
            final colunas = constraints.maxWidth >= 760 ? 2 : 1;
            final largura =
                (constraints.maxWidth - (colunas - 1) * 10) / colunas;
            return Wrap(
              spacing: 10,
              runSpacing: 10,
              children: atalhos
                  .map((atalho) => SizedBox(
                      width: largura, child: _CartaoAtalho(atalho: atalho)))
                  .toList(),
            );
          }),
          const SizedBox(height: 23),
          Row(
            key: _chaveCanteiros,
            children: [
              const Expanded(
                  child: TituloSecao(titulo: 'Canteiros cadastrados')),
              FilledButton.icon(
                  onPressed: () => _novoCanteiro(context),
                  icon: const Icon(Icons.add_rounded, size: 18),
                  label: const Text('Novo canteiro')),
            ],
          ),
          const SizedBox(height: 11),
          if (widget.canteiros.isEmpty)
            Container(
                width: double.infinity,
                padding: const EdgeInsets.all(22),
                decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(18)),
                child: const Text(
                    'Nenhum canteiro cadastrado. Use “Novo canteiro” para começar.'))
          else
            ...widget.canteiros.map((canteiro) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: _CartaoCanteiroConfiguracao(
                    canteiro: canteiro,
                    aoCalibrar: () => _calibrar(context, canteiro),
                    aoRemover: () => _confirmarRemocao(context, canteiro),
                    aoEditarMeta: () =>
                        _editarMetas(context, idInicial: canteiro.id),
                  ),
                )),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(15),
            decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(17),
                border: Border.all(color: const Color(0xFFE6ECE7))),
            child: const Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.lightbulb_outline_rounded,
                      color: CoresHortasmart.verde, size: 21),
                  SizedBox(width: 10),
                  Expanded(
                      child: Text(
                          'Cada sensor deve ser calibrado individualmente. Registre as leituras brutas de referência seca e úmida do próprio sensor, pois os valores podem variar entre módulos.',
                          style: TextStyle(
                              fontSize: 11,
                              height: 1.45,
                              color: CoresHortasmart.textoSecundario))),
                ]),
          ),
          const SizedBox(height: 24),
        ]),
      ),
    );
  }
}

class _AtalhoConfiguracao {
  const _AtalhoConfiguracao(
      this.icone, this.titulo, this.subtitulo, this.aoTocar);
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
              border: Border.all(color: const Color(0xFFE5ECE6))),
          child: Row(children: [
            Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                    color: CoresHortasmart.verdeClaro,
                    borderRadius: BorderRadius.circular(13)),
                child:
                    Icon(atalho.icone, color: CoresHortasmart.verde, size: 23)),
            const SizedBox(width: 11),
            Expanded(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                  Text(atalho.titulo,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w900,
                          color: CoresHortasmart.texto)),
                  const SizedBox(height: 4),
                  Text(atalho.subtitulo,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          fontSize: 10,
                          height: 1.3,
                          color: CoresHortasmart.textoSecundario)),
                ])),
            const SizedBox(width: 6),
            const Icon(Icons.chevron_right_rounded,
                color: CoresHortasmart.textoSecundario, size: 20),
          ]),
        ),
      ),
    );
  }
}

class _CartaoCanteiroConfiguracao extends StatelessWidget {
  const _CartaoCanteiroConfiguracao(
      {required this.canteiro,
      required this.aoCalibrar,
      required this.aoRemover,
      required this.aoEditarMeta});
  final Canteiro canteiro;
  final VoidCallback aoCalibrar;
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

  @override
  Widget build(BuildContext context) {
    final estado = classificarUmidade(canteiro.umidadeAtual);
    return Container(
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: const Color(0xFFE5ECE6))),
      child: Column(children: [
        Row(children: [
          Container(
              width: 47,
              height: 47,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                  color: CoresHortasmart.verdeClaro,
                  borderRadius: BorderRadius.circular(14)),
              child: Text(_emoji, style: const TextStyle(fontSize: 25))),
          const SizedBox(width: 11),
          Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                Text(canteiro.cultura,
                    style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w900,
                        color: CoresHortasmart.texto)),
                const SizedBox(height: 3),
                Text(
                    '${canteiro.nome} · Sensor ${canteiro.id.split('-').last.toUpperCase()}',
                    style: const TextStyle(
                        fontSize: 10, color: CoresHortasmart.textoSecundario)),
                const SizedBox(height: 4),
                Text('Meta: ${canteiro.metaUmidade.round()}%',
                    style: const TextStyle(
                        fontSize: 10, color: CoresHortasmart.textoSecundario)),
              ])),
          Container(
              width: 9,
              height: 9,
              decoration: BoxDecoration(
                  color: canteiro.conectado
                      ? estado.cor
                      : CoresHortasmart.vermelho,
                  shape: BoxShape.circle)),
        ]),
        const SizedBox(height: 12),
        Row(children: [
          Expanded(
              child: OutlinedButton.icon(
                  onPressed: aoCalibrar,
                  icon: const Icon(Icons.tune_rounded, size: 17),
                  label: const Text('Calibrar'))),
          const SizedBox(width: 8),
          Expanded(
              child: OutlinedButton.icon(
                  onPressed: aoEditarMeta,
                  icon: const Icon(Icons.track_changes_rounded, size: 17),
                  label: const Text('Meta'))),
          const SizedBox(width: 4),
          IconButton(
              onPressed: aoRemover,
              tooltip: 'Remover canteiro',
              style: IconButton.styleFrom(
                  backgroundColor: const Color(0xFFFFEFEE),
                  foregroundColor: CoresHortasmart.vermelho),
              icon: const Icon(Icons.delete_outline_rounded)),
        ]),
      ]),
    );
  }
}

import 'package:flutter/material.dart';
import '../../compartilhado/componentes/indicador_umidade.dart';
import '../../compartilhado/componentes/area_pagina.dart';
import '../../compartilhado/componentes/etiqueta_status.dart';
import '../../compartilhado/componentes/titulo_secao.dart';
import '../../compartilhado/constantes/cores.dart';
import '../../dados/modelos/canteiro.dart';

import 'seletor_modo.dart';

class TelaIrrigacao extends StatefulWidget {
  const TelaIrrigacao({
    super.key,
    required this.canteiros,
    required this.aoAtualizarCanteiro,
    this.canteiroInicialId,
  });

  final List<Canteiro> canteiros;
  final ValueChanged<Canteiro> aoAtualizarCanteiro;
  final String? canteiroInicialId;

  @override
  State<TelaIrrigacao> createState() => _TelaIrrigacaoState();
}

class _TelaIrrigacaoState extends State<TelaIrrigacao> {
  String? _idSelecionado;
  double _metaTemporaria = 65;
  int _intervaloTemporario = 4;

  Canteiro? get _selecionado {
    if (widget.canteiros.isEmpty) return null;

    for (final canteiro in widget.canteiros) {
      if (canteiro.id == _idSelecionado) {
        return canteiro;
      }
    }

    return widget.canteiros.first;
  }

  @override
  void initState() {
    super.initState();

    if (widget.canteiros.isNotEmpty) {
      Canteiro inicial = widget.canteiros.first;

      for (final item in widget.canteiros) {
        if (item.id == widget.canteiroInicialId) {
          inicial = item;
          break;
        }
      }

      _idSelecionado = inicial.id;
      _carregarConfiguracao(inicial);
    }
  }

  @override
  void didUpdateWidget(covariant TelaIrrigacao oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.canteiros.isEmpty) {
      _idSelecionado = null;
      return;
    }

    if (widget.canteiroInicialId != oldWidget.canteiroInicialId &&
        widget.canteiroInicialId != null) {
      for (final item in widget.canteiros) {
        if (item.id == widget.canteiroInicialId) {
          _idSelecionado = item.id;
          _carregarConfiguracao(item);
          return;
        }
      }
    }

    final selecaoExiste = widget.canteiros.any(
      (canteiro) => canteiro.id == _idSelecionado,
    );

    if (!selecaoExiste) {
      _idSelecionado = widget.canteiros.first.id;
      _carregarConfiguracao(widget.canteiros.first);
    }
  }

  void _carregarConfiguracao(Canteiro canteiro) {
    _metaTemporaria = canteiro.metaUmidade;
    _intervaloTemporario = canteiro.intervaloHoras;
  }

  void _selecionar(Canteiro canteiro) {
    setState(() {
      _idSelecionado = canteiro.id;
      _carregarConfiguracao(canteiro);
    });
  }

  void _mensagem(String texto) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(texto),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _salvar(Canteiro canteiro) {
    widget.aoAtualizarCanteiro(
      canteiro.copiarCom(
        metaUmidade: _metaTemporaria,
        intervaloHoras: _intervaloTemporario,
      ),
    );

    _mensagem('Configurações atualizadas.');
  }

  void _alternarBomba(Canteiro canteiro, bool ligar) {
    widget.aoAtualizarCanteiro(
      canteiro.copiarCom(irrigando: ligar),
    );

    _mensagem(
      ligar ? 'Irrigação iniciada.' : 'Irrigação interrompida.',
    );
  }

  @override
  Widget build(BuildContext context) {
    if (widget.canteiros.isEmpty) {
      return const AreaPagina(
        child: Center(
          child: Padding(
            padding: EdgeInsets.all(28),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.water_drop_outlined,
                  size: 42,
                  color: CoresHortasmart.verde,
                ),
                SizedBox(height: 12),
                Text(
                  'Nenhum canteiro cadastrado',
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 17,
                    color: CoresHortasmart.texto,
                  ),
                ),
                SizedBox(height: 6),
                Text(
                  'Acesse Configurações para cadastrar um canteiro e configurar a irrigação.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 13,
                    height: 1.4,
                    color: CoresHortasmart.textoSecundario,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final canteiro = _selecionado!;
    final automatico = canteiro.modo == ModoIrrigacao.automatico;

    return AreaPagina(
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const TituloSecao(
              titulo: 'Selecione o canteiro',
              detalhe: 'Controle individual',
            ),
            const SizedBox(height: 10),
            DropdownButtonFormField<String>(
              key: ValueKey(canteiro.id),
              initialValue: canteiro.id,
              isExpanded: true,
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.grass_rounded),
                labelText: 'Canteiro que será controlado',
              ),
              items: widget.canteiros.map((item) {
                return DropdownMenuItem(
                  value: item.id,
                  child: Text(
                    '${item.cultura} · ${item.nome}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                );
              }).toList(),
              onChanged: (id) {
                for (final item in widget.canteiros) {
                  if (item.id == id) {
                    _selecionar(item);
                    break;
                  }
                }
              },
            ),
            const SizedBox(height: 15),
            LayoutBuilder(
              builder: (context, constraints) {
                final resumo = _CartaoResumoCanteiro(
                  canteiro: canteiro,
                );

                final modoMeta = _CartaoModoMeta(
                  canteiro: canteiro,
                  metaTemporaria: _metaTemporaria,
                  intervaloTemporario: _intervaloTemporario,
                  aoAlterarModo: (modo) {
                    widget.aoAtualizarCanteiro(
                      canteiro.copiarCom(modo: modo),
                    );
                  },
                  aoAlterarMeta: (valor) {
                    setState(() => _metaTemporaria = valor);
                  },
                  aoAlterarIntervalo: (valor) {
                    setState(() => _intervaloTemporario = valor);
                  },
                );

                final comando = _CartaoComandoManual(
                  canteiro: canteiro,
                  automatico: automatico,
                  aoIniciar: () => _alternarBomba(canteiro, true),
                  aoParar: () => _alternarBomba(canteiro, false),
                );

                final estado = _CartaoEstadoBomba(
                  canteiro: canteiro,
                );

                final seguranca = _CartaoSeguranca(
                  automatico: automatico,
                );

                if (constraints.maxWidth >= 820) {
                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          children: [
                            resumo,
                            const SizedBox(height: 13),
                            modoMeta,
                          ],
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          children: [
                            comando,
                            const SizedBox(height: 13),
                            estado,
                            const SizedBox(height: 13),
                            seguranca,
                          ],
                        ),
                      ),
                    ],
                  );
                }

                return Column(
                  children: [
                    resumo,
                    const SizedBox(height: 13),
                    modoMeta,
                    const SizedBox(height: 13),
                    comando,
                    const SizedBox(height: 13),
                    estado,
                    const SizedBox(height: 13),
                    seguranca,
                  ],
                );
              },
            ),
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: () => _salvar(canteiro),
                icon: const Icon(Icons.save_outlined),
                label: const Text('Salvar configurações do canteiro'),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

class _CartaoResumoCanteiro extends StatelessWidget {
  const _CartaoResumoCanteiro({
    required this.canteiro,
  });

  final Canteiro canteiro;

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
      width: double.infinity,
      padding: const EdgeInsets.all(17),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE5ECE6)),
      ),
      child: Row(
        children: [
          Container(
            width: 58,
            height: 58,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: CoresHortasmart.verdeClaro,
              borderRadius: BorderRadius.circular(17),
            ),
            child: Text(
              _emoji,
              style: const TextStyle(fontSize: 31),
            ),
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  canteiro.cultura,
                  style: const TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 16,
                    color: CoresHortasmart.texto,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  '${canteiro.nome} · Sensor ${canteiro.id.split('-').last.toUpperCase()}',
                  style: const TextStyle(
                    fontSize: 11,
                    color: CoresHortasmart.textoSecundario,
                  ),
                ),
                const SizedBox(height: 10),
                ClipRRect(
                  borderRadius: BorderRadius.circular(99),
                  child: LinearProgressIndicator(
                    value: (canteiro.umidadeAtual / 100)
                        .clamp(0.0, 1.0)
                        .toDouble(),
                    minHeight: 6,
                    backgroundColor: const Color(0xFFE8EEE8),
                    valueColor: AlwaysStoppedAnimation(estado.cor),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${canteiro.umidadeAtual.round()}%',
                style: TextStyle(
                  fontSize: 28,
                  height: 1.1,
                  fontWeight: FontWeight.w900,
                  color: estado.cor,
                  letterSpacing: -1,
                ),
              ),
              const SizedBox(height: 5),
              EtiquetaStatus(
                texto: estado.texto,
                cor: estado.cor,
                fundo: estado.fundo,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _CartaoModoMeta extends StatelessWidget {
  const _CartaoModoMeta({
    required this.canteiro,
    required this.metaTemporaria,
    required this.intervaloTemporario,
    required this.aoAlterarModo,
    required this.aoAlterarMeta,
    required this.aoAlterarIntervalo,
  });

  final Canteiro canteiro;
  final double metaTemporaria;
  final int intervaloTemporario;
  final ValueChanged<ModoIrrigacao> aoAlterarModo;
  final ValueChanged<double> aoAlterarMeta;
  final ValueChanged<int> aoAlterarIntervalo;

  @override
  Widget build(BuildContext context) {
    final automatico = canteiro.modo == ModoIrrigacao.automatico;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE5ECE6)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Modo de operação',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w900,
              color: CoresHortasmart.texto,
            ),
          ),
          const SizedBox(height: 11),
          SeletorModo(
            modo: canteiro.modo,
            aoAlterar: aoAlterarModo,
          ),
          const SizedBox(height: 20),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              const Expanded(
                child: Text(
                  'Meta de umidade',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: CoresHortasmart.texto,
                  ),
                ),
              ),
              const Icon(
                Icons.water_drop_outlined,
                color: CoresHortasmart.verde,
                size: 19,
              ),
              const SizedBox(width: 4),
              Text(
                '${metaTemporaria.round()}%',
                style: const TextStyle(
                  fontSize: 24,
                  height: 1,
                  fontWeight: FontWeight.w900,
                  color: CoresHortasmart.verde,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          const Text(
            'Objetivo de umidade para este canteiro.',
            style: TextStyle(
              fontSize: 11,
              color: CoresHortasmart.textoSecundario,
            ),
          ),
          Slider(
            value: metaTemporaria.clamp(0.0, 100.0).toDouble(),
            min: 0,
            max: 100,
            divisions: 20,
            label: '${metaTemporaria.round()}%',
            onChanged: aoAlterarMeta,
          ),
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '0% · Seco',
                style: TextStyle(
                  fontSize: 10,
                  color: CoresHortasmart.textoSecundario,
                ),
              ),
              Text(
                '100% · Úmido',
                style: TextStyle(
                  fontSize: 10,
                  color: CoresHortasmart.textoSecundario,
                ),
              ),
            ],
          ),
          if (automatico) ...[
            const SizedBox(height: 18),
            DropdownButtonFormField<int>(
              key: ValueKey(_intervaloValido(intervaloTemporario)),
              initialValue: _intervaloValido(intervaloTemporario),
              isExpanded: true,
              decoration: const InputDecoration(
                labelText: 'Verificar a cada',
                prefixIcon: Icon(Icons.schedule_rounded),
              ),
              items: const [1, 2, 4, 6, 8, 12, 24]
                  .map(
                    (h) => DropdownMenuItem(
                      value: h,
                      child: Text('$h ${h == 1 ? 'hora' : 'horas'}'),
                    ),
                  )
                  .toList(),
              onChanged: (valor) {
                if (valor != null) {
                  aoAlterarIntervalo(valor);
                }
              },
            ),
          ],
        ],
      ),
    );
  }

  int _intervaloValido(int intervalo) {
    const intervalos = [1, 2, 4, 6, 8, 12, 24];

    return intervalos.contains(intervalo) ? intervalo : 4;
  }
}

class _CartaoComandoManual extends StatelessWidget {
  const _CartaoComandoManual({
    required this.canteiro,
    required this.automatico,
    required this.aoIniciar,
    required this.aoParar,
  });

  final Canteiro canteiro;
  final bool automatico;
  final VoidCallback aoIniciar;
  final VoidCallback aoParar;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE5ECE6)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Controle manual',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w900,
              color: CoresHortasmart.texto,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            automatico
                ? 'Mude para o modo manual para ativar os comandos.'
                : 'Inicie ou interrompa a irrigação deste canteiro.',
            style: const TextStyle(
              fontSize: 11,
              height: 1.4,
              color: CoresHortasmart.textoSecundario,
            ),
          ),
          const SizedBox(height: 15),
          LayoutBuilder(
            builder: (context, constraints) {
              final empilhados = constraints.maxWidth < 360;

              final iniciar = FilledButton.icon(
                onPressed: automatico || canteiro.irrigando ? null : aoIniciar,
                icon: const Icon(Icons.play_arrow_rounded),
                label: const Text('Iniciar irrigação'),
                style: FilledButton.styleFrom(
                  backgroundColor: CoresHortasmart.verde,
                  minimumSize: const Size(0, 48),
                ),
              );

              final parar = FilledButton.icon(
                onPressed: automatico || !canteiro.irrigando ? null : aoParar,
                icon: const Icon(Icons.stop_circle_outlined),
                label: const Text('Parar irrigação'),
                style: FilledButton.styleFrom(
                  backgroundColor: CoresHortasmart.vermelho,
                  minimumSize: const Size(0, 48),
                ),
              );

              if (empilhados) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    iniciar,
                    const SizedBox(height: 9),
                    parar,
                  ],
                );
              }

              return Row(
                children: [
                  Expanded(child: iniciar),
                  const SizedBox(width: 9),
                  Expanded(child: parar),
                ],
              );
            },
          ),
          if (automatico) ...[
            const SizedBox(height: 12),
            const Text(
              'Os botões ficam bloqueados no modo automático para evitar comandos conflitantes.',
              style: TextStyle(
                fontSize: 10,
                color: CoresHortasmart.textoSecundario,
                height: 1.35,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _CartaoEstadoBomba extends StatelessWidget {
  const _CartaoEstadoBomba({
    required this.canteiro,
  });

  final Canteiro canteiro;

  @override
  Widget build(BuildContext context) {
    final cor = canteiro.irrigando
        ? CoresHortasmart.azul
        : CoresHortasmart.textoSecundario;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFEAF5ED),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFD9EBDD)),
      ),
      child: Row(
        children: [
          Container(
            width: 43,
            height: 43,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(13),
            ),
            child: const Icon(
              Icons.water_drop_rounded,
              color: CoresHortasmart.verde,
              size: 23,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Bomba de irrigação',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w900,
                    color: CoresHortasmart.texto,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Status: ${canteiro.irrigando ? 'Ligada' : 'Desligada'}',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: cor,
                  ),
                ),
              ],
            ),
          ),
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(
              color: canteiro.irrigando
                  ? CoresHortasmart.azul
                  : const Color(0xFF9CAAA0),
              shape: BoxShape.circle,
            ),
          ),
        ],
      ),
    );
  }
}

class _CartaoSeguranca extends StatelessWidget {
  const _CartaoSeguranca({
    required this.automatico,
  });

  final bool automatico;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: const Color(0xFFF0F6F1),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.eco_rounded,
            color: CoresHortasmart.verde,
            size: 21,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              automatico
                  ? 'No modo automático, o ESP32 deverá avaliar a umidade e a programação e aplicar limites de segurança antes de ligar a bomba.'
                  : 'No modo manual, confirme a disponibilidade de água e as proteções da instalação antes de iniciar.',
              style: const TextStyle(
                fontSize: 11,
                height: 1.45,
                color: CoresHortasmart.texto,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';

import '../../compartilhado/componentes/area_pagina.dart';
import '../../compartilhado/componentes/etiqueta_status.dart';
import '../../compartilhado/componentes/indicador_umidade.dart';
import '../../compartilhado/componentes/titulo_secao.dart';
import '../../compartilhado/constantes/cores.dart';
import '../../dados/modelos/canteiro.dart';

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

  bool get _outroCanteiroIrrigando {
    return widget.canteiros.any(
      (canteiro) => canteiro.id != _idSelecionado && canteiro.irrigando,
    );
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
      final primeiro = widget.canteiros.first;
      _idSelecionado = primeiro.id;
      _carregarConfiguracao(primeiro);
    }
  }

  void _carregarConfiguracao(Canteiro canteiro) {
    _metaTemporaria = canteiro.metaUmidade;
    _intervaloTemporario = _intervaloValido(canteiro.intervaloHoras);
  }

  int _intervaloValido(int intervalo) {
    const intervalos = [1, 2, 4, 6, 8, 12, 24];

    return intervalos.contains(intervalo) ? intervalo : 4;
  }

  void _selecionar(Canteiro canteiro) {
    setState(() {
      _idSelecionado = canteiro.id;
      _carregarConfiguracao(canteiro);
    });
  }

  void _mensagem(String texto) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(texto), behavior: SnackBarBehavior.floating),
    );
  }

  void _alterarModo(Canteiro canteiro, ModoIrrigacao modo) {
    widget.aoAtualizarCanteiro(canteiro.copiarCom(modo: modo));
  }

  void _salvar(Canteiro canteiro) {
    widget.aoAtualizarCanteiro(
      canteiro.copiarCom(
        metaUmidade: _metaTemporaria,
        intervaloHoras: _intervaloTemporario,
      ),
    );

    _mensagem('Configurações enviadas para atualização.');
  }

  void _alternarIrrigacao(Canteiro canteiro, bool ligar) {
    if (canteiro.modo == ModoIrrigacao.automatico) {
      _mensagem('Altere para o modo manual antes de utilizar os comandos.');
      return;
    }

    if (ligar && !canteiro.conectado) {
      _mensagem('O sensor deste canteiro está desconectado.');
      return;
    }

    if (ligar && _outroCanteiroIrrigando) {
      _mensagem(
        'Outro canteiro já está irrigando. '
        'Interrompa primeiro para iniciar este.',
      );
      return;
    }

    widget.aoAtualizarCanteiro(canteiro.copiarCom(irrigando: ligar));

    _mensagem(
      ligar
          ? 'Solicitação de início registrada.'
          : 'Solicitação de interrupção registrada.',
    );
  }

  Future<void> _selecionarEConfirmar(Canteiro canteiro, bool ligar) async {
    if (!ligar || !_outroCanteiroIrrigando) {
      _alternarIrrigacao(canteiro, ligar);
      return;
    }

    final outro = widget.canteiros.firstWhere(
      (item) => item.id != canteiro.id && item.irrigando,
    );

    final confirmou = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Outro canteiro está irrigando'),
            content: Text(
              '${outro.nome} está com a irrigação ativa. '
              'Interrompa a irrigação dele antes de iniciar ${canteiro.nome}.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Entendi'),
              ),
            ],
          ),
    );

    if (confirmou == true) {
      _mensagem('Selecione o canteiro que está irrigando para interrompê-lo.');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.canteiros.isEmpty) {
      return const AreaPagina(
        child: Center(
          child: Padding(
            padding: EdgeInsets.all(24),
            child: _EstadoVazioIrrigacao(),
          ),
        ),
      );
    }

    final canteiro = _selecionado;

    if (canteiro == null) {
      return const SizedBox.shrink();
    }

    final automatico = canteiro.modo == ModoIrrigacao.automatico;

    return AreaPagina(
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const _ApresentacaoIrrigacao(),

            const SizedBox(height: 22),

            const TituloSecao(
              titulo: 'Selecione o canteiro',
              detalhe: 'Escolha a plantação que deseja controlar',
            ),

            const SizedBox(height: 11),

            _SeletorCanteiro(
              canteiros: widget.canteiros,
              canteiroSelecionado: canteiro,
              aoSelecionar: _selecionar,
            ),

            const SizedBox(height: 17),

            LayoutBuilder(
              builder: (context, constraints) {
                final resumo = _CartaoResumoCanteiro(canteiro: canteiro);

                final modoMeta = _CartaoModoMeta(
                  canteiro: canteiro,
                  metaTemporaria: _metaTemporaria,
                  intervaloTemporario: _intervaloTemporario,
                  aoAlterarModo: (modo) {
                    _alterarModo(canteiro, modo);
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
                  outroCanteiroIrrigando: _outroCanteiroIrrigando,
                  aoIniciar: () {
                    _selecionarEConfirmar(canteiro, true);
                  },
                  aoParar: () {
                    _alternarIrrigacao(canteiro, false);
                  },
                );

                final estado = _CartaoEstadoIrrigacao(canteiro: canteiro);

                final seguranca = _CartaoSeguranca(automatico: automatico);

                if (constraints.maxWidth >= 900) {
                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          children: [
                            resumo,
                            const SizedBox(height: 14),
                            modoMeta,
                          ],
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          children: [
                            comando,
                            const SizedBox(height: 14),
                            estado,
                            const SizedBox(height: 14),
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
                    const SizedBox(height: 14),
                    modoMeta,
                    const SizedBox(height: 14),
                    comando,
                    const SizedBox(height: 14),
                    estado,
                    const SizedBox(height: 14),
                    seguranca,
                  ],
                );
              },
            ),

            const SizedBox(height: 16),

            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: () => _salvar(canteiro),
                style: FilledButton.styleFrom(
                  backgroundColor: CoresHortasmart.verde,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(0, 50),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(13),
                  ),
                ),
                icon: const Icon(Icons.save_outlined),
                label: const Text(
                  'Salvar configurações do canteiro',
                  textAlign: TextAlign.center,
                ),
              ),
            ),

            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

// ============================================================
// APRESENTAÇÃO
// ============================================================

class _ApresentacaoIrrigacao extends StatelessWidget {
  const _ApresentacaoIrrigacao();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(21),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF087B4B), Color(0xFF05643D)],
        ),
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF075C39).withValues(alpha: 0.13),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            right: -15,
            top: -40,
            child: Container(
              width: 125,
              height: 125,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.10),
                  width: 19,
                ),
              ),
            ),
          ),
          const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'CONTROLE INTELIGENTE',
                style: TextStyle(
                  color: Color(0xFFD5F0DF),
                  letterSpacing: 1.2,
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                ),
              ),
              SizedBox(height: 9),
              Text(
                'Irrigação da sua horta',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  height: 1.2,
                  letterSpacing: -0.5,
                  fontWeight: FontWeight.w900,
                ),
              ),
              SizedBox(height: 7),
              Text(
                'Gerencie a umidade e o funcionamento '
                'da irrigação de cada canteiro.',
                style: TextStyle(
                  color: Color(0xFFE4F4E9),
                  fontSize: 12,
                  height: 1.45,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ============================================================
// ESTADO VAZIO
// ============================================================

class _EstadoVazioIrrigacao extends StatelessWidget {
  const _EstadoVazioIrrigacao();

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 420),
      padding: const EdgeInsets.all(25),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFE5ECE6)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: CoresHortasmart.verdeClaro,
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Icon(
              Icons.water_drop_outlined,
              color: CoresHortasmart.verde,
              size: 34,
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Nenhum canteiro cadastrado',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 17,
              color: CoresHortasmart.texto,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Cadastre um canteiro nas configurações para '
            'começar a organizar a irrigação da sua horta.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12,
              height: 1.5,
              color: CoresHortasmart.textoSecundario,
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// SELETOR DE CANTEIRO
// ============================================================

class _SeletorCanteiro extends StatelessWidget {
  const _SeletorCanteiro({
    required this.canteiros,
    required this.canteiroSelecionado,
    required this.aoSelecionar,
  });

  final List<Canteiro> canteiros;
  final Canteiro canteiroSelecionado;
  final ValueChanged<Canteiro> aoSelecionar;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE5ECE6)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.grass_rounded, color: CoresHortasmart.verde, size: 19),
              SizedBox(width: 8),
              Text(
                'Canteiro que será controlado',
                style: TextStyle(
                  color: CoresHortasmart.texto,
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 11),
          DropdownButtonFormField<String>(
            key: ValueKey(canteiroSelecionado.id),
            initialValue: canteiroSelecionado.id,
            isExpanded: true,
            decoration: InputDecoration(
              filled: true,
              fillColor: const Color(0xFFF6F9F6),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 12,
              ),
              prefixIcon: const Icon(
                Icons.spa_outlined,
                color: CoresHortasmart.verde,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFFE1EAE3)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFFE1EAE3)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(
                  color: CoresHortasmart.verde,
                  width: 1.3,
                ),
              ),
            ),
            items:
                canteiros.map((item) {
                  return DropdownMenuItem<String>(
                    value: item.id,
                    child: Text(
                      '${item.cultura} · ${item.nome}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  );
                }).toList(),
            onChanged: (id) {
              for (final item in canteiros) {
                if (item.id == id) {
                  aoSelecionar(item);
                  break;
                }
              }
            },
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 7,
            children: [
              _PillStatus(
                texto:
                    canteiroSelecionado.conectado
                        ? 'Sensor conectado'
                        : 'Sensor desconectado',
                icone:
                    canteiroSelecionado.conectado
                        ? Icons.wifi_rounded
                        : Icons.wifi_off_rounded,
                cor:
                    canteiroSelecionado.conectado
                        ? CoresHortasmart.verde
                        : CoresHortasmart.vermelho,
              ),
              _PillStatus(
                texto:
                    canteiroSelecionado.modo == ModoIrrigacao.automatico
                        ? 'Automático'
                        : 'Manual',
                icone: Icons.tune_rounded,
                cor: const Color(0xFF247BA0),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ============================================================
// RESUMO DO CANTEIRO
// ============================================================

class _CartaoResumoCanteiro extends StatelessWidget {
  const _CartaoResumoCanteiro({required this.canteiro});

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
      case 'manjericão':
      case 'manjericao':
        return '🌱';
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
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compacto = constraints.maxWidth < 360;

          final identificacao = Row(
            children: [
              Container(
                width: 54,
                height: 54,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: CoresHortasmart.verdeClaro,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(_emoji, style: const TextStyle(fontSize: 29)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      canteiro.cultura.isEmpty
                          ? canteiro.nome
                          : canteiro.cultura,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 15,
                        color: CoresHortasmart.texto,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      canteiro.nome,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 11,
                        color: CoresHortasmart.textoSecundario,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );

          final umidade = Column(
            crossAxisAlignment:
                compacto ? CrossAxisAlignment.start : CrossAxisAlignment.end,
            children: [
              Text(
                '${canteiro.umidadeAtual.round()}%',
                style: TextStyle(
                  fontSize: compacto ? 29 : 31,
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
          );

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (compacto) ...[
                identificacao,
                const SizedBox(height: 17),
                umidade,
              ] else
                Row(
                  children: [
                    Expanded(child: identificacao),
                    const SizedBox(width: 10),
                    umidade,
                  ],
                ),
              const SizedBox(height: 15),
              ClipRRect(
                borderRadius: BorderRadius.circular(99),
                child: LinearProgressIndicator(
                  value: canteiro.umidadeAtual.clamp(0.0, 100.0) / 100,
                  minHeight: 7,
                  backgroundColor: const Color(0xFFE8EEE8),
                  valueColor: AlwaysStoppedAnimation<Color>(estado.cor),
                ),
              ),
              const SizedBox(height: 11),
              Wrap(
                spacing: 13,
                runSpacing: 8,
                children: [
                  _InformacaoPequena(
                    icone: Icons.flag_outlined,
                    texto: 'Meta ${canteiro.metaUmidade.round()}%',
                  ),
                  _InformacaoPequena(
                    icone:
                        canteiro.conectado
                            ? Icons.wifi_rounded
                            : Icons.wifi_off_rounded,
                    texto:
                        canteiro.conectado ? 'Sensor conectado' : 'Sem conexão',
                    cor:
                        canteiro.conectado
                            ? CoresHortasmart.verde
                            : CoresHortasmart.vermelho,
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }
}

// ============================================================
// MODO E META DE UMIDADE
// ============================================================

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
          const _TituloCartao(
            titulo: 'Modo de operação',
            icone: Icons.tune_rounded,
          ),
          const SizedBox(height: 13),

          _SeletorModoResponsivo(modo: canteiro.modo, aoAlterar: aoAlterarModo),

          const SizedBox(height: 22),

          Row(
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
              Text(
                '${metaTemporaria.round()}%',
                style: const TextStyle(
                  fontSize: 25,
                  height: 1,
                  fontWeight: FontWeight.w900,
                  color: CoresHortasmart.verde,
                ),
              ),
            ],
          ),

          const SizedBox(height: 5),

          const Text(
            'Defina o nível de umidade desejado para este canteiro.',
            style: TextStyle(
              fontSize: 11,
              height: 1.4,
              color: CoresHortasmart.textoSecundario,
            ),
          ),

          Slider(
            value: metaTemporaria.clamp(0.0, 100.0).toDouble(),
            min: 0,
            max: 100,
            divisions: 20,
            label: '${metaTemporaria.round()}%',
            activeColor: CoresHortasmart.verde,
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
            const SizedBox(height: 20),

            DropdownButtonFormField<int>(
              key: ValueKey(intervaloTemporario),
              initialValue: intervaloTemporario,
              isExpanded: true,
              decoration: InputDecoration(
                labelText: 'Intervalo de verificação',
                prefixIcon: const Icon(
                  Icons.schedule_rounded,
                  color: CoresHortasmart.verde,
                ),
                filled: true,
                fillColor: const Color(0xFFF6F9F6),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFFE1EAE3)),
                ),
              ),
              items:
                  const [1, 2, 4, 6, 8, 12, 24].map((horas) {
                    return DropdownMenuItem<int>(
                      value: horas,
                      child: Text('$horas ${horas == 1 ? 'hora' : 'horas'}'),
                    );
                  }).toList(),
              onChanged: (valor) {
                if (valor != null) {
                  aoAlterarIntervalo(valor);
                }
              },
            ),

            const SizedBox(height: 8),

            const Text(
              'O intervalo define a frequência de verificação da umidade.',
              style: TextStyle(
                fontSize: 10,
                height: 1.35,
                color: CoresHortasmart.textoSecundario,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ============================================================
// SELETOR DE MODO
// ============================================================

class _SeletorModoResponsivo extends StatelessWidget {
  const _SeletorModoResponsivo({required this.modo, required this.aoAlterar});

  final ModoIrrigacao modo;
  final ValueChanged<ModoIrrigacao> aoAlterar;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: const Color(0xFFF2F6F2),
        borderRadius: BorderRadius.circular(14),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compacto = constraints.maxWidth < 290;

          Widget opcao({
            required String titulo,
            required String descricao,
            required IconData icone,
            required ModoIrrigacao valor,
          }) {
            final selecionado = modo == valor;

            return Expanded(
              child: Material(
                color: selecionado ? Colors.white : Colors.transparent,
                borderRadius: BorderRadius.circular(11),
                child: InkWell(
                  onTap: () => aoAlterar(valor),
                  borderRadius: BorderRadius.circular(11),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 12,
                    ),
                    child: Column(
                      children: [
                        Icon(
                          icone,
                          size: 21,
                          color:
                              selecionado
                                  ? CoresHortasmart.verde
                                  : CoresHortasmart.textoSecundario,
                        ),
                        const SizedBox(height: 5),
                        Text(
                          titulo,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                            color:
                                selecionado
                                    ? CoresHortasmart.verde
                                    : CoresHortasmart.texto,
                          ),
                        ),
                        if (!compacto) ...[
                          const SizedBox(height: 3),
                          Text(
                            descricao,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 9,
                              height: 1.2,
                              color: CoresHortasmart.textoSecundario,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            );
          }

          return Row(
            children: [
              opcao(
                titulo: 'Automático',
                descricao: 'Controle pelo sistema',
                icone: Icons.auto_mode_rounded,
                valor: ModoIrrigacao.automatico,
              ),
              const SizedBox(width: 5),
              opcao(
                titulo: 'Manual',
                descricao: 'Controle pelo usuário',
                icone: Icons.touch_app_outlined,
                valor: ModoIrrigacao.manual,
              ),
            ],
          );
        },
      ),
    );
  }
}

// ============================================================
// CONTROLE MANUAL
// ============================================================

class _CartaoComandoManual extends StatelessWidget {
  const _CartaoComandoManual({
    required this.canteiro,
    required this.automatico,
    required this.outroCanteiroIrrigando,
    required this.aoIniciar,
    required this.aoParar,
  });

  final Canteiro canteiro;
  final bool automatico;
  final bool outroCanteiroIrrigando;
  final VoidCallback aoIniciar;
  final VoidCallback aoParar;

  @override
  Widget build(BuildContext context) {
    final conectado = canteiro.conectado;

    final podeIniciar =
        !automatico &&
        conectado &&
        !canteiro.irrigando &&
        !outroCanteiroIrrigando;

    final podeParar = !automatico && canteiro.irrigando;

    String orientacao;

    if (automatico) {
      orientacao =
          'No modo automático, o sistema decide quando iniciar a irrigação.';
    } else if (!conectado) {
      orientacao =
          'O sensor está desconectado. Verifique a conexão antes de iniciar.';
    } else if (outroCanteiroIrrigando) {
      orientacao =
          'Outro canteiro está irrigando. A irrigação é organizada um canteiro por vez.';
    } else {
      orientacao =
          'Utilize os comandos para iniciar ou interromper a irrigação.';
    }

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
          const _TituloCartao(
            titulo: 'Controle manual',
            icone: Icons.touch_app_outlined,
          ),

          const SizedBox(height: 7),

          Text(
            orientacao,
            style: const TextStyle(
              fontSize: 11,
              height: 1.45,
              color: CoresHortasmart.textoSecundario,
            ),
          ),

          const SizedBox(height: 17),

          LayoutBuilder(
            builder: (context, constraints) {
              final empilhados = constraints.maxWidth < 390;

              final iniciar = FilledButton.icon(
                onPressed: podeIniciar ? aoIniciar : null,
                icon: const Icon(Icons.play_arrow_rounded),
                label: const Text(
                  'Iniciar irrigação',
                  textAlign: TextAlign.center,
                  maxLines: 2,
                ),
                style: FilledButton.styleFrom(
                  backgroundColor: CoresHortasmart.verde,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(0, 50),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 10,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              );

              final parar = FilledButton.icon(
                onPressed: podeParar ? aoParar : null,
                icon: const Icon(Icons.stop_circle_outlined),
                label: const Text(
                  'Interromper',
                  textAlign: TextAlign.center,
                  maxLines: 2,
                ),
                style: FilledButton.styleFrom(
                  backgroundColor: CoresHortasmart.vermelho,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(0, 50),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 10,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              );

              if (empilhados) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [iniciar, const SizedBox(height: 9), parar],
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
            const _AvisoInformativo(
              texto:
                  'Os comandos manuais ficam desativados enquanto o modo automático estiver selecionado.',
            ),
          ],
        ],
      ),
    );
  }
}

// ============================================================
// ESTADO INDIVIDUAL DA IRRIGAÇÃO
// ============================================================

class _CartaoEstadoIrrigacao extends StatelessWidget {
  const _CartaoEstadoIrrigacao({required this.canteiro});

  final Canteiro canteiro;

  @override
  Widget build(BuildContext context) {
    final irrigando = canteiro.irrigando;
    final cor =
        irrigando ? const Color(0xFF247BA0) : CoresHortasmart.textoSecundario;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(17),
      decoration: BoxDecoration(
        color: irrigando ? const Color(0xFFEAF5FA) : const Color(0xFFF0F7F1),
        borderRadius: BorderRadius.circular(19),
        border: Border.all(
          color: irrigando ? const Color(0xFFD4E8F1) : const Color(0xFFDCEBDF),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Estado da irrigação',
            style: TextStyle(
              color: CoresHortasmart.texto,
              fontSize: 14,
              fontWeight: FontWeight.w900,
            ),
          ),

          const SizedBox(height: 13),

          Row(
            children: [
              Container(
                width: 45,
                height: 45,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(Icons.water_drop_rounded, color: cor, size: 24),
              ),

              const SizedBox(width: 12),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      canteiro.nome,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: CoresHortasmart.texto,
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      irrigando ? 'Irrigação ativa' : 'Irrigação pausada',
                      style: TextStyle(
                        color: cor,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),

              Container(
                width: 11,
                height: 11,
                decoration: BoxDecoration(
                  color:
                      irrigando
                          ? const Color(0xFF247BA0)
                          : const Color(0xFF9CAAA0),
                  shape: BoxShape.circle,
                  boxShadow:
                      irrigando
                          ? [
                            BoxShadow(
                              color: cor.withValues(alpha: 0.25),
                              blurRadius: 8,
                              spreadRadius: 2,
                            ),
                          ]
                          : null,
                ),
              ),
            ],
          ),

          const SizedBox(height: 13),

          const Divider(height: 1, color: Color(0xFFDCE8DF)),

          const SizedBox(height: 11),

          Wrap(
            spacing: 14,
            runSpacing: 8,
            children: [
              _InformacaoPequena(
                icone: Icons.water_drop_outlined,
                texto: irrigando ? 'Em funcionamento' : 'Sem fluxo registrado',
                cor: cor,
              ),
              _InformacaoPequena(
                icone:
                    canteiro.conectado
                        ? Icons.wifi_rounded
                        : Icons.wifi_off_rounded,
                texto:
                    canteiro.conectado
                        ? 'Sensor conectado'
                        : 'Sensor desconectado',
                cor:
                    canteiro.conectado
                        ? CoresHortasmart.verde
                        : CoresHortasmart.vermelho,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ============================================================
// SEGURANÇA E ORIENTAÇÕES
// ============================================================

class _CartaoSeguranca extends StatelessWidget {
  const _CartaoSeguranca({required this.automatico});

  final bool automatico;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: const Color(0xFFF0F6F1),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE0EBE2)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.info_outline_rounded,
            color: CoresHortasmart.verde,
            size: 21,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              automatico
                  ? 'No modo automático, o ESP32 deverá avaliar a umidade, '
                      'o intervalo configurado e os limites de segurança '
                      'antes de acionar a irrigação.'
                  : 'No modo manual, os comandos são direcionados ao '
                      'canteiro selecionado. A irrigação deve ser realizada '
                      'em apenas um canteiro por vez.',
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

// ============================================================
// COMPONENTES AUXILIARES
// ============================================================

class _TituloCartao extends StatelessWidget {
  const _TituloCartao({required this.titulo, required this.icone});

  final String titulo;
  final IconData icone;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icone, color: CoresHortasmart.verde, size: 20),
        const SizedBox(width: 9),
        Expanded(
          child: Text(
            titulo,
            style: const TextStyle(
              color: CoresHortasmart.texto,
              fontSize: 14,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
      ],
    );
  }
}

class _InformacaoPequena extends StatelessWidget {
  const _InformacaoPequena({
    required this.icone,
    required this.texto,
    this.cor = CoresHortasmart.textoSecundario,
  });

  final IconData icone;
  final String texto;
  final Color cor;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icone, color: cor, size: 14),
        const SizedBox(width: 5),
        Flexible(
          child: Text(
            texto,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: cor,
              fontSize: 10,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}

class _PillStatus extends StatelessWidget {
  const _PillStatus({
    required this.texto,
    required this.icone,
    required this.cor,
  });

  final String texto;
  final IconData icone;
  final Color cor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: cor.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(30),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icone, color: cor, size: 14),
          const SizedBox(width: 5),
          Text(
            texto,
            style: TextStyle(
              color: cor,
              fontSize: 10,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _AvisoInformativo extends StatelessWidget {
  const _AvisoInformativo({required this.texto});

  final String texto;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color(0xFFF0F6F1),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.info_outline_rounded,
            color: CoresHortasmart.verde,
            size: 16,
          ),
          const SizedBox(width: 7),
          Expanded(
            child: Text(
              texto,
              style: const TextStyle(
                fontSize: 10,
                height: 1.4,
                color: CoresHortasmart.textoSecundario,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

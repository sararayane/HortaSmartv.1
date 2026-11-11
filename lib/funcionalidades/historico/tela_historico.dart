import 'package:flutter/material.dart';

import '../../compartilhado/componentes/area_pagina.dart';
import '../../compartilhado/componentes/etiqueta_status.dart';
import '../../compartilhado/componentes/indicador_umidade.dart';
import '../../compartilhado/componentes/titulo_secao.dart';
import '../../compartilhado/constantes/cores.dart';
import '../../dados/modelos/canteiro.dart';
import '../../dados/modelos/evento_irrigacao.dart';
import '../../dados/repositorios/repositorio_historico.dart';
import 'grafico_umidade.dart';

class TelaHistorico extends StatefulWidget {
  const TelaHistorico({super.key, required this.canteiros});

  final List<Canteiro> canteiros;

  @override
  State<TelaHistorico> createState() => _TelaHistoricoState();
}

class _TelaHistoricoState extends State<TelaHistorico> {
  final RepositorioHistorico _repositorio = RepositorioHistorico();

  int _periodoDias = 7;
  String? _canteiroSelecionadoId;

  Stream<List<EventoIrrigacao>>? _eventosStream;

  Canteiro? get _canteiroSelecionado {
    for (final canteiro in widget.canteiros) {
      if (canteiro.id == _canteiroSelecionadoId) {
        return canteiro;
      }
    }

    return widget.canteiros.isEmpty ? null : widget.canteiros.first;
  }

  String get _nomePeriodo {
    switch (_periodoDias) {
      case 1:
        return 'últimas 24 horas';
      case 30:
        return 'últimos 30 dias';
      default:
        return 'últimos 7 dias';
    }
  }

  @override
  void initState() {
    super.initState();

    if (widget.canteiros.isNotEmpty) {
      _canteiroSelecionadoId = widget.canteiros.first.id;
    }

    _configurarStreamEventos();
  }

  @override
  void didUpdateWidget(covariant TelaHistorico oldWidget) {
    super.didUpdateWidget(oldWidget);

    final selecaoExiste = widget.canteiros.any(
      (canteiro) => canteiro.id == _canteiroSelecionadoId,
    );

    if (!selecaoExiste) {
      _canteiroSelecionadoId =
          widget.canteiros.isEmpty ? null : widget.canteiros.first.id;

      _configurarStreamEventos();
    }
  }

  void _configurarStreamEventos() {
    final id = _canteiroSelecionadoId;

    if (id == null) {
      _eventosStream = null;
      return;
    }

    _eventosStream = _repositorio.acompanharEventosIrrigacao(
      canteiroId: id,
      periodoDias: _periodoDias,
    );
  }

  void _selecionarCanteiro(String? id) {
    if (id == null) return;

    setState(() {
      _canteiroSelecionadoId = id;
      _configurarStreamEventos();
    });
  }

  void _selecionarPeriodo(int dias) {
    setState(() {
      _periodoDias = dias;
      _configurarStreamEventos();
    });
  }

  @override
  Widget build(BuildContext context) {
    final totalCanteiros = widget.canteiros.length;

    final conectados =
        widget.canteiros.where((canteiro) => canteiro.conectado).length;

    final irrigando =
        widget.canteiros.where((canteiro) => canteiro.irrigando).length;

    final alertas =
        widget.canteiros.where((canteiro) {
          return !canteiro.conectado ||
              canteiro.umidadeAtual < canteiro.metaUmidade;
        }).length;

    final selecionado = _canteiroSelecionado;

    return AreaPagina(
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const _CabecalhoHistorico(),

            const SizedBox(height: 23),

            const TituloSecao(
              titulo: 'Visão geral',
              detalhe: 'Situação atual dos seus canteiros',
            ),

            const SizedBox(height: 12),

            _construirIndicadores(
              total: totalCanteiros,
              conectados: conectados,
              irrigando: irrigando,
              alertas: alertas,
            ),

            const SizedBox(height: 25),

            const TituloSecao(
              titulo: 'Histórico do período',
              detalhe: 'Selecione o intervalo que deseja acompanhar',
            ),

            const SizedBox(height: 12),

            _construirFiltroPeriodo(),

            const SizedBox(height: 20),

            const TituloSecao(
              titulo: 'Canteiro selecionado',
              detalhe: 'Escolha os dados que deseja consultar',
            ),

            const SizedBox(height: 11),

            if (selecionado == null)
              const _CartaoVazio()
            else
              _SeletorCanteiroHistorico(
                canteiros: widget.canteiros,
                selecionado: selecionado,
                aoSelecionar: _selecionarCanteiro,
              ),

            const SizedBox(height: 22),

            const TituloSecao(
              titulo: 'Evolução da umidade',
              detalhe: 'Leituras armazenadas no Firebase',
            ),

            const SizedBox(height: 11),

            if (selecionado == null)
              const _CartaoSemHistorico(
                icone: Icons.show_chart_rounded,
                titulo: 'Nenhum canteiro selecionado',
                descricao:
                    'Cadastre um canteiro para acompanhar a evolução da umidade.',
              )
            else
              GraficoUmidade(
                key: ValueKey('${selecionado.id}_$_periodoDias'),
                canteiroId: selecionado.id,
                canteiroNome: selecionado.nome,
                periodoDias: _periodoDias,
              ),

            const SizedBox(height: 24),

            const TituloSecao(
              titulo: 'Atividade de irrigação',
              detalhe: 'Solicitações registradas pelo aplicativo',
            ),

            const SizedBox(height: 11),

            if (selecionado == null)
              const _CartaoVazio()
            else
              _ListaEventosIrrigacao(
                stream: _eventosStream,
                periodo: _nomePeriodo,
              ),

            const SizedBox(height: 24),

            const TituloSecao(
              titulo: 'Consumo de água',
              detalhe: 'Acompanhamento do volume utilizado',
            ),

            const SizedBox(height: 11),

            const _CartaoSemHistorico(
              icone: Icons.opacity_rounded,
              titulo: 'Medição de consumo pendente',
              descricao:
                  'O consumo real será apresentado quando tivermos '
                  'registros de vazão ou um cálculo calibrado com o '
                  'tempo efetivo de funcionamento da irrigação.',
            ),

            const SizedBox(height: 24),

            TituloSecao(
              titulo: 'Leituras atuais por canteiro',
              detalhe:
                  '$totalCanteiros '
                  '${totalCanteiros == 1 ? 'canteiro cadastrado' : 'canteiros cadastrados'}',
            ),

            const SizedBox(height: 12),

            if (widget.canteiros.isEmpty)
              const _EstadoVazioHistorico()
            else
              ...widget.canteiros.map(
                (canteiro) => Padding(
                  padding: const EdgeInsets.only(bottom: 11),
                  child: _CartaoLeituraCanteiro(canteiro: canteiro),
                ),
              ),

            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _construirIndicadores({
    required int total,
    required int conectados,
    required int irrigando,
    required int alertas,
  }) {
    final indicadores = [
      _IndicadorHistorico(
        titulo: 'Canteiros',
        valor: '$total',
        descricao: 'Cadastrados',
        icone: Icons.spa_outlined,
        cor: CoresHortasmart.verde,
        fundo: CoresHortasmart.verdeClaro,
      ),
      _IndicadorHistorico(
        titulo: 'Conectados',
        valor: '$conectados',
        descricao: 'Sensores',
        icone: Icons.wifi_rounded,
        cor: const Color(0xFF247BA0),
        fundo: const Color(0xFFE8F4FD),
      ),
      _IndicadorHistorico(
        titulo: 'Irrigando',
        valor: '$irrigando',
        descricao: 'Atualmente',
        icone: Icons.water_drop_outlined,
        cor: const Color(0xFF2787B7),
        fundo: const Color(0xFFE8F4FD),
      ),
      _IndicadorHistorico(
        titulo: 'Atenção',
        valor: '$alertas',
        descricao: 'Canteiros',
        icone: Icons.notifications_active_outlined,
        cor: alertas > 0 ? const Color(0xFFB7791F) : CoresHortasmart.verde,
        fundo:
            alertas > 0 ? const Color(0xFFFFF4E2) : CoresHortasmart.verdeClaro,
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final colunas =
            constraints.maxWidth >= 850
                ? 4
                : constraints.maxWidth >= 340
                ? 2
                : 1;

        const espacamento = 10.0;

        final largura =
            (constraints.maxWidth - espacamento * (colunas - 1)) / colunas;

        return Wrap(
          spacing: espacamento,
          runSpacing: espacamento,
          children: [
            for (final indicador in indicadores)
              SizedBox(width: largura, child: indicador),
          ],
        );
      },
    );
  }

  Widget _construirFiltroPeriodo() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: SegmentedButton<int>(
        segments: const [
          ButtonSegment(value: 1, label: Text('24 horas')),
          ButtonSegment(value: 7, label: Text('7 dias')),
          ButtonSegment(value: 30, label: Text('30 dias')),
        ],
        selected: {_periodoDias},
        showSelectedIcon: false,
        onSelectionChanged: (valores) {
          _selecionarPeriodo(valores.first);
        },
        style: const ButtonStyle(
          visualDensity: VisualDensity.compact,
          textStyle: WidgetStatePropertyAll(
            TextStyle(fontSize: 11, fontWeight: FontWeight.w700),
          ),
        ),
      ),
    );
  }
}

// ============================================================
// CABEÇALHO
// ============================================================

class _CabecalhoHistorico extends StatelessWidget {
  const _CabecalhoHistorico();

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
            color: const Color(0xFF075C39).withValues(alpha: 0.12),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            right: -16,
            top: -43,
            child: Container(
              width: 130,
              height: 130,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.09),
                  width: 20,
                ),
              ),
            ),
          ),
          const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'ACOMPANHAMENTO',
                style: TextStyle(
                  color: Color(0xFFD5F0DF),
                  fontSize: 10,
                  letterSpacing: 1.2,
                  fontWeight: FontWeight.w800,
                ),
              ),
              SizedBox(height: 9),
              Text(
                'Histórico da sua horta',
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
                'Acompanhe as informações e o desenvolvimento '
                'dos seus canteiros em um só lugar.',
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
// SELETOR DE CANTEIRO
// ============================================================

class _SeletorCanteiroHistorico extends StatelessWidget {
  const _SeletorCanteiroHistorico({
    required this.canteiros,
    required this.selecionado,
    required this.aoSelecionar,
  });

  final List<Canteiro> canteiros;
  final Canteiro selecionado;
  final ValueChanged<String?> aoSelecionar;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(17),
        border: Border.all(color: const Color(0xFFE5ECE6)),
      ),
      child: DropdownButtonFormField<String>(
        key: ValueKey(selecionado.id),
        initialValue: selecionado.id,
        isExpanded: true,
        decoration: InputDecoration(
          labelText: 'Canteiro para consultar',
          prefixIcon: const Icon(
            Icons.spa_outlined,
            color: CoresHortasmart.verde,
          ),
          filled: true,
          fillColor: const Color(0xFFF6F9F6),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFFE1EAE3)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFFE1EAE3)),
          ),
        ),
        items:
            canteiros.map((canteiro) {
              return DropdownMenuItem<String>(
                value: canteiro.id,
                child: Text(
                  '${canteiro.cultura} · ${canteiro.nome}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              );
            }).toList(),
        onChanged: aoSelecionar,
      ),
    );
  }
}

// ============================================================
// INDICADORES
// ============================================================

class _IndicadorHistorico extends StatelessWidget {
  const _IndicadorHistorico({
    required this.titulo,
    required this.valor,
    required this.descricao,
    required this.icone,
    required this.cor,
    required this.fundo,
  });

  final String titulo;
  final String valor;
  final String descricao;
  final IconData icone;
  final Color cor;
  final Color fundo;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(17),
        border: Border.all(color: const Color(0xFFE5ECE6)),
      ),
      child: Row(
        children: [
          Container(
            width: 39,
            height: 39,
            decoration: BoxDecoration(
              color: fundo,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icone, color: cor, size: 21),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  titulo,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 10,
                    color: CoresHortasmart.textoSecundario,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 3),
                FittedBox(
                  alignment: Alignment.centerLeft,
                  fit: BoxFit.scaleDown,
                  child: Text(
                    valor,
                    style: TextStyle(
                      color: cor,
                      fontSize: 22,
                      height: 1.1,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  descricao,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 9,
                    color: CoresHortasmart.textoSecundario,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// EVENTOS DE IRRIGAÇÃO
// ============================================================

class _ListaEventosIrrigacao extends StatelessWidget {
  const _ListaEventosIrrigacao({required this.stream, required this.periodo});

  final Stream<List<EventoIrrigacao>>? stream;
  final String periodo;

  String _formatarData(DateTime data) {
    final dia = data.day.toString().padLeft(2, '0');
    final mes = data.month.toString().padLeft(2, '0');
    final hora = data.hour.toString().padLeft(2, '0');
    final minuto = data.minute.toString().padLeft(2, '0');

    return '$dia/$mes/${data.year} às $hora:$minuto';
  }

  String _tituloEvento(EventoIrrigacao evento) {
    switch (evento.tipo) {
      case 'inicio_solicitado':
        return 'Solicitação de início';
      case 'parada_solicitada':
        return 'Solicitação de interrupção';
      default:
        return 'Evento de irrigação';
    }
  }

  IconData _iconeEvento(EventoIrrigacao evento) {
    switch (evento.tipo) {
      case 'inicio_solicitado':
        return Icons.play_arrow_rounded;
      case 'parada_solicitada':
        return Icons.stop_rounded;
      default:
        return Icons.water_drop_outlined;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (stream == null) {
      return const _CartaoVazio();
    }

    return StreamBuilder<List<EventoIrrigacao>>(
      stream: stream,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return const _CartaoSemHistorico(
            icone: Icons.error_outline_rounded,
            titulo: 'Não foi possível carregar as atividades',
            descricao:
                'Verifique sua conexão com o Firebase e as permissões de acesso.',
          );
        }

        if (snapshot.connectionState == ConnectionState.waiting &&
            !snapshot.hasData) {
          return const SizedBox(
            height: 100,
            child: Center(
              child: CircularProgressIndicator(
                strokeWidth: 2.5,
                color: CoresHortasmart.verde,
              ),
            ),
          );
        }

        final eventos = snapshot.data ?? [];

        if (eventos.isEmpty) {
          return _CartaoSemHistorico(
            icone: Icons.history_rounded,
            titulo: 'Nenhuma atividade registrada',
            descricao:
                'Não foram encontradas solicitações de irrigação para $periodo.',
          );
        }

        return Container(
          width: double.infinity,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: const Color(0xFFE5ECE6)),
          ),
          child: Column(
            children: [
              for (int indice = 0; indice < eventos.length; indice++) ...[
                _LinhaEvento(
                  evento: eventos[indice],
                  titulo: _tituloEvento(eventos[indice]),
                  icone: _iconeEvento(eventos[indice]),
                  dataFormatada:
                      eventos[indice].registradoEm == null
                          ? 'Data não disponível'
                          : _formatarData(eventos[indice].registradoEm!),
                ),
                if (indice != eventos.length - 1)
                  const Divider(height: 18, color: Color(0xFFE9EEE9)),
              ],
            ],
          ),
        );
      },
    );
  }
}

class _LinhaEvento extends StatelessWidget {
  const _LinhaEvento({
    required this.evento,
    required this.titulo,
    required this.icone,
    required this.dataFormatada,
  });

  final EventoIrrigacao evento;
  final String titulo;
  final IconData icone;
  final String dataFormatada;

  @override
  Widget build(BuildContext context) {
    final confirmado = evento.estadoConfirmado;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 37,
          height: 37,
          decoration: BoxDecoration(
            color: const Color(0xFFEAF5ED),
            borderRadius: BorderRadius.circular(11),
          ),
          child: Icon(icone, color: CoresHortasmart.verde, size: 20),
        ),
        const SizedBox(width: 11),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                titulo,
                style: const TextStyle(
                  color: CoresHortasmart.texto,
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '$dataFormatada · ${evento.modo == 'automatico' ? 'Automático' : 'Manual'}',
                style: const TextStyle(
                  color: CoresHortasmart.textoSecundario,
                  fontSize: 10,
                ),
              ),
              const SizedBox(height: 5),
              Text(
                confirmado
                    ? 'Estado confirmado pelo dispositivo'
                    : 'Solicitação registrada pelo aplicativo; '
                        'a execução física ainda não foi confirmada.',
                style: TextStyle(
                  color:
                      confirmado
                          ? CoresHortasmart.verde
                          : const Color(0xFF95702D),
                  fontSize: 10,
                  height: 1.35,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ============================================================
// CARTÃO SEM HISTÓRICO
// ============================================================

class _CartaoSemHistorico extends StatelessWidget {
  const _CartaoSemHistorico({
    required this.icone,
    required this.titulo,
    required this.descricao,
  });

  final IconData icone;
  final String titulo;
  final String descricao;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(19),
        border: Border.all(color: const Color(0xFFE5ECE6)),
      ),
      child: Column(
        children: [
          Container(
            width: 51,
            height: 51,
            decoration: BoxDecoration(
              color: CoresHortasmart.verdeClaro,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(icone, color: CoresHortasmart.verde, size: 26),
          ),
          const SizedBox(height: 12),
          Text(
            titulo,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: CoresHortasmart.texto,
              fontSize: 13,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 7),
          Text(
            descricao,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: CoresHortasmart.textoSecundario,
              fontSize: 11,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// LEITURAS ATUAIS DOS CANTEIROS
// ============================================================

class _CartaoLeituraCanteiro extends StatelessWidget {
  const _CartaoLeituraCanteiro({required this.canteiro});

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

    final corStatus =
        canteiro.conectado ? estado.cor : CoresHortasmart.vermelho;

    final fundoStatus =
        canteiro.conectado ? estado.fundo : CoresHortasmart.vermelhoClaro;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(17),
        border: Border.all(color: const Color(0xFFE5ECE6)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 43,
                height: 43,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: CoresHortasmart.verdeClaro,
                  borderRadius: BorderRadius.circular(13),
                ),
                child: Text(_emoji, style: const TextStyle(fontSize: 24)),
              ),
              const SizedBox(width: 11),
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
                        fontSize: 13,
                        color: CoresHortasmart.texto,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      canteiro.nome,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 10,
                        color: CoresHortasmart.textoSecundario,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '${canteiro.umidadeAtual.round()}%',
                style: TextStyle(
                  color: corStatus,
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.7,
                ),
              ),
            ],
          ),
          const SizedBox(height: 13),
          ClipRRect(
            borderRadius: BorderRadius.circular(99),
            child: LinearProgressIndicator(
              value: canteiro.umidadeAtual.clamp(0.0, 100.0) / 100,
              minHeight: 6,
              backgroundColor: const Color(0xFFEAF0E9),
              valueColor: AlwaysStoppedAnimation<Color>(corStatus),
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              EtiquetaStatus(
                texto: canteiro.conectado ? estado.texto : 'Sem conexão',
                cor: corStatus,
                fundo: fundoStatus,
              ),
              _InformacaoStatus(
                icone: Icons.flag_outlined,
                texto: 'Meta ${canteiro.metaUmidade.round()}%',
              ),
              _InformacaoStatus(
                icone:
                    canteiro.irrigando
                        ? Icons.water_drop_rounded
                        : Icons.pause_circle_outline_rounded,
                texto: canteiro.irrigando ? 'Irrigando' : 'Pausado',
                cor:
                    canteiro.irrigando
                        ? CoresHortasmart.azul
                        : CoresHortasmart.textoSecundario,
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

class _CartaoVazio extends StatelessWidget {
  const _CartaoVazio();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE5ECE6)),
      ),
      child: const Text(
        'Cadastre um canteiro para acompanhar os dados.',
        textAlign: TextAlign.center,
        style: TextStyle(color: CoresHortasmart.textoSecundario, fontSize: 12),
      ),
    );
  }
}

class _EstadoVazioHistorico extends StatelessWidget {
  const _EstadoVazioHistorico();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE5ECE6)),
      ),
      child: const Column(
        children: [
          Icon(Icons.spa_outlined, color: CoresHortasmart.verde, size: 34),
          SizedBox(height: 10),
          Text(
            'Nenhum canteiro cadastrado',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: CoresHortasmart.texto,
              fontWeight: FontWeight.w800,
              fontSize: 14,
            ),
          ),
          SizedBox(height: 6),
          Text(
            'Quando você cadastrar seus canteiros, '
            'as leituras atuais aparecerão aqui.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: CoresHortasmart.textoSecundario,
              fontSize: 11,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}

class _InformacaoStatus extends StatelessWidget {
  const _InformacaoStatus({
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
        Icon(icone, size: 13, color: cor),
        const SizedBox(width: 4),
        Text(
          texto,
          style: TextStyle(
            color: cor,
            fontSize: 10,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

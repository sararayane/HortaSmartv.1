import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../compartilhado/constantes/cores.dart';
import '../../dados/modelos/leitura_umidade.dart';
import '../../dados/repositorios/repositorio_historico.dart';

class GraficoUmidade extends StatefulWidget {
  const GraficoUmidade({
    super.key,
    required this.canteiroId,
    required this.canteiroNome,
    required this.periodoDias,
  });

  final String canteiroId;
  final String canteiroNome;
  final int periodoDias;

  @override
  State<GraficoUmidade> createState() => _GraficoUmidadeState();
}

class _GraficoUmidadeState extends State<GraficoUmidade> {
  final RepositorioHistorico _repositorio = RepositorioHistorico();

  late Stream<List<LeituraUmidade>> _stream;
  late DateTime _inicioPeriodo;

  @override
  void initState() {
    super.initState();
    _configurarStream();
  }

  @override
  void didUpdateWidget(covariant GraficoUmidade oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.canteiroId != widget.canteiroId ||
        oldWidget.periodoDias != widget.periodoDias) {
      _configurarStream();
    }
  }

  void _configurarStream() {
    _inicioPeriodo = DateTime.now().subtract(
      Duration(days: widget.periodoDias),
    );

    _stream = _repositorio.acompanharLeiturasUmidade(
      canteiroId: widget.canteiroId,
      periodoDias: widget.periodoDias,
    );
  }

  double get _maxX {
    return widget.periodoDias == 1 ? 24 : widget.periodoDias.toDouble();
  }

  double _converterX(DateTime data) {
    final diferenca = data.difference(_inicioPeriodo);

    if (widget.periodoDias == 1) {
      return diferenca.inSeconds / 3600;
    }

    return diferenca.inSeconds / 86400;
  }

  DateTime _converterData(double x) {
    if (widget.periodoDias == 1) {
      return _inicioPeriodo.add(Duration(seconds: (x * 3600).round()));
    }

    return _inicioPeriodo.add(Duration(seconds: (x * 86400).round()));
  }

  String _formatarDataHora(DateTime data) {
    final dia = data.day.toString().padLeft(2, '0');
    final mes = data.month.toString().padLeft(2, '0');
    final hora = data.hour.toString().padLeft(2, '0');
    final minuto = data.minute.toString().padLeft(2, '0');

    if (widget.periodoDias == 1) {
      return '$dia/$mes às $hora:$minuto';
    }

    return '$dia/$mes às $hora:$minuto';
  }

  String _rotuloEixo(double valor) {
    final data = _converterData(valor);

    if (widget.periodoDias == 1) {
      return '${data.hour.toString().padLeft(2, '0')}h';
    }

    final dia = data.day.toString().padLeft(2, '0');
    final mes = data.month.toString().padLeft(2, '0');

    return '$dia/$mes';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(15, 17, 15, 15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE5ECE6)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 37,
                height: 37,
                decoration: BoxDecoration(
                  color: CoresHortasmart.verdeClaro,
                  borderRadius: BorderRadius.circular(11),
                ),
                child: const Icon(
                  Icons.show_chart_rounded,
                  color: CoresHortasmart.verde,
                  size: 21,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Umidade do solo',
                      style: TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 14,
                        color: CoresHortasmart.texto,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      widget.canteiroNome,
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
            ],
          ),
          const SizedBox(height: 15),
          StreamBuilder<List<LeituraUmidade>>(
            stream: _stream,
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return const _EstadoGrafico(
                  icone: Icons.error_outline_rounded,
                  titulo: 'Não foi possível carregar o gráfico',
                  descricao:
                      'Verifique a conexão com o Firebase e as permissões de acesso.',
                );
              }

              if (snapshot.connectionState == ConnectionState.waiting &&
                  !snapshot.hasData) {
                return const SizedBox(
                  height: 210,
                  child: Center(
                    child: CircularProgressIndicator(
                      color: CoresHortasmart.verde,
                      strokeWidth: 2.5,
                    ),
                  ),
                );
              }

              final leituras = snapshot.data ?? [];

              if (leituras.isEmpty) {
                return const _EstadoGrafico(
                  icone: Icons.query_stats_rounded,
                  titulo: 'Ainda não há leituras registradas',
                  descricao:
                      'Quando o ESP32 enviar as leituras de umidade ao Firebase, '
                      'a evolução do solo aparecerá neste gráfico.',
                );
              }

              return _construirGrafico(leituras);
            },
          ),
          const SizedBox(height: 12),
          const Row(
            children: [
              Icon(Icons.circle, size: 9, color: CoresHortasmart.verde),
              SizedBox(width: 6),
              Text(
                'Umidade registrada no Firebase',
                style: TextStyle(
                  fontSize: 10,
                  color: CoresHortasmart.textoSecundario,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _construirGrafico(List<LeituraUmidade> leituras) {
    final spots =
        leituras
            .where((leitura) => leitura.registradoEm != null)
            .map((leitura) {
              return FlSpot(
                _converterX(leitura.registradoEm!),
                leitura.umidade.clamp(0.0, 100.0).toDouble(),
              );
            })
            .where((spot) => spot.x >= 0 && spot.x <= _maxX)
            .toList()
          ..sort((a, b) => a.x.compareTo(b.x));

    if (spots.isEmpty) {
      return const _EstadoGrafico(
        icone: Icons.query_stats_rounded,
        titulo: 'Nenhuma leitura neste período',
        descricao:
            'Não foram encontrados registros com data e hora para o intervalo selecionado.',
      );
    }

    final intervaloHorizontal = widget.periodoDias == 1 ? 25.0 : 25.0;

    final intervaloVertical =
        widget.periodoDias == 1
            ? 6.0
            : widget.periodoDias == 7
            ? 1.0
            : 5.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          height: 215,
          child: LineChart(
            LineChartData(
              minX: 0,
              maxX: _maxX,
              minY: 0,
              maxY: 100,
              clipData: const FlClipData.all(),
              gridData: FlGridData(
                show: true,
                drawVerticalLine: true,
                horizontalInterval: intervaloHorizontal,
                verticalInterval: intervaloVertical,
                getDrawingHorizontalLine:
                    (_) =>
                        const FlLine(color: Color(0xFFE9EEE9), strokeWidth: 1),
                getDrawingVerticalLine:
                    (_) =>
                        const FlLine(color: Color(0xFFF0F3F0), strokeWidth: 1),
              ),
              borderData: FlBorderData(show: false),
              titlesData: FlTitlesData(
                topTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                rightTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 33,
                    interval: 25,
                    getTitlesWidget: (valor, meta) {
                      return Padding(
                        padding: const EdgeInsets.only(right: 5),
                        child: Text(
                          '${valor.toInt()}%',
                          style: const TextStyle(
                            fontSize: 9,
                            color: CoresHortasmart.textoSecundario,
                          ),
                        ),
                      );
                    },
                  ),
                ),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 27,
                    interval: intervaloVertical,
                    getTitlesWidget: (valor, meta) {
                      return Padding(
                        padding: const EdgeInsets.only(top: 7),
                        child: Text(
                          _rotuloEixo(valor),
                          style: const TextStyle(
                            fontSize: 9,
                            color: CoresHortasmart.textoSecundario,
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
              lineTouchData: LineTouchData(
                handleBuiltInTouches: true,
                touchTooltipData: LineTouchTooltipData(
                  getTooltipItems: (spotsTocados) {
                    return spotsTocados.map((spot) {
                      final data = _converterData(spot.x);

                      return LineTooltipItem(
                        '${spot.y.toStringAsFixed(1)}%\n'
                        '${_formatarDataHora(data)}',
                        const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 10,
                          height: 1.4,
                        ),
                      );
                    }).toList();
                  },
                ),
              ),
              lineBarsData: [
                LineChartBarData(
                  spots: spots,
                  isCurved: true,
                  curveSmoothness: 0.2,
                  color: CoresHortasmart.verde,
                  barWidth: 2.8,
                  isStrokeCapRound: true,
                  dotData: FlDotData(show: spots.length <= 20),
                  belowBarData: BarAreaData(
                    show: true,
                    color: CoresHortasmart.verde.withValues(alpha: 0.08),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 9),
        Text(
          '${leituras.length} '
          '${leituras.length == 1 ? 'leitura encontrada' : 'leituras encontradas'} '
          'no período selecionado',
          style: const TextStyle(
            fontSize: 10,
            color: CoresHortasmart.textoSecundario,
          ),
        ),
      ],
    );
  }
}

class _EstadoGrafico extends StatelessWidget {
  const _EstadoGrafico({
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
      constraints: const BoxConstraints(minHeight: 175),
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 22),
      decoration: BoxDecoration(
        color: const Color(0xFFF7FAF7),
        borderRadius: BorderRadius.circular(15),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icone, color: CoresHortasmart.verde, size: 34),
          const SizedBox(height: 11),
          Text(
            titulo,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: CoresHortasmart.texto,
              fontSize: 12,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 7),
          Text(
            descricao,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: CoresHortasmart.textoSecundario,
              fontSize: 10,
              height: 1.45,
            ),
          ),
        ],
      ),
    );
  }
}

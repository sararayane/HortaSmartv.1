import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../compartilhado/constantes/cores.dart';

class GraficoUmidade extends StatelessWidget {
  const GraficoUmidade({super.key, required this.periodoDias});
  final int periodoDias;

  static const _cores = [
    CoresHortasmart.verde,
    Color(0xFFF2A51A),
    Color(0xFFEF4E5B),
    Color(0xFF3989D8),
  ];
  static const _nomes = ['Alface', 'Tomate', 'Cenoura', 'Rúcula'];

  List<List<FlSpot>> get _series {
    if (periodoDias == 1) {
      return const [
        [FlSpot(0, 65), FlSpot(2, 58), FlSpot(4, 61), FlSpot(6, 63), FlSpot(8, 68), FlSpot(10, 72), FlSpot(12, 69), FlSpot(14, 64), FlSpot(16, 62), FlSpot(18, 67), FlSpot(20, 70), FlSpot(22, 68), FlSpot(24, 72)],
        [FlSpot(0, 38), FlSpot(2, 42), FlSpot(4, 39), FlSpot(6, 44), FlSpot(8, 47), FlSpot(10, 52), FlSpot(12, 49), FlSpot(14, 43), FlSpot(16, 45), FlSpot(18, 46), FlSpot(20, 47), FlSpot(22, 45), FlSpot(24, 50)],
        [FlSpot(0, 20), FlSpot(2, 22), FlSpot(4, 18), FlSpot(6, 25), FlSpot(8, 31), FlSpot(10, 34), FlSpot(12, 28), FlSpot(14, 26), FlSpot(16, 23), FlSpot(18, 28), FlSpot(20, 25), FlSpot(22, 23), FlSpot(24, 20)],
        [FlSpot(0, 35), FlSpot(2, 30), FlSpot(4, 28), FlSpot(6, 31), FlSpot(8, 37), FlSpot(10, 40), FlSpot(12, 37), FlSpot(14, 34), FlSpot(16, 38), FlSpot(18, 36), FlSpot(20, 39), FlSpot(22, 37), FlSpot(24, 34)],
      ];
    }
    return const [
      [FlSpot(0, 63), FlSpot(1, 60), FlSpot(2, 66), FlSpot(3, 70), FlSpot(4, 67), FlSpot(5, 64), FlSpot(6, 72)],
      [FlSpot(0, 42), FlSpot(1, 44), FlSpot(2, 39), FlSpot(3, 48), FlSpot(4, 51), FlSpot(5, 46), FlSpot(6, 50)],
      [FlSpot(0, 24), FlSpot(1, 20), FlSpot(2, 29), FlSpot(3, 31), FlSpot(4, 26), FlSpot(5, 23), FlSpot(6, 28)],
      [FlSpot(0, 36), FlSpot(1, 31), FlSpot(2, 35), FlSpot(3, 39), FlSpot(4, 41), FlSpot(5, 37), FlSpot(6, 34)],
    ];
  }

  @override
  Widget build(BuildContext context) {
    final maxX = periodoDias == 1 ? 24.0 : 6.0;
    return Container(
      padding: const EdgeInsets.fromLTRB(13, 17, 16, 13),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), border: Border.all(color: const Color(0xFFE6ECE7))),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Padding(
          padding: EdgeInsets.only(left: 3),
          child: Row(children: [
            Icon(Icons.show_chart_rounded, color: CoresHortasmart.verde, size: 20),
            SizedBox(width: 7),
            Text('Umidade do solo', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 14, color: CoresHortasmart.texto)),
          ]),
        ),
        const SizedBox(height: 6),
        const Padding(padding: EdgeInsets.only(left: 3), child: Text('Variação por canteiro · dados ilustrativos', style: TextStyle(fontSize: 11, color: CoresHortasmart.textoSecundario))),
        const SizedBox(height: 16),
        SizedBox(
          height: 205,
          child: LineChart(
            LineChartData(
              minX: 0,
              maxX: maxX,
              minY: 0,
              maxY: 100,
              clipData: const FlClipData.all(),
              gridData: FlGridData(
                show: true,
                drawVerticalLine: true,
                horizontalInterval: 25,
                verticalInterval: periodoDias == 1 ? 4 : 1,
                getDrawingHorizontalLine: (_) => const FlLine(color: Color(0xFFE9EEE9), strokeWidth: 1),
                getDrawingVerticalLine: (_) => const FlLine(color: Color(0xFFF0F3F0), strokeWidth: 1),
              ),
              borderData: FlBorderData(show: false),
              titlesData: FlTitlesData(
                topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                leftTitles: AxisTitles(sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 31,
                  interval: 25,
                  getTitlesWidget: (valor, meta) => Padding(
                    padding: const EdgeInsets.only(right: 4),
                    child: Text('${valor.toInt()}', style: const TextStyle(fontSize: 10, color: CoresHortasmart.textoSecundario)),
                  ),
                )),
                bottomTitles: AxisTitles(sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 25,
                  interval: periodoDias == 1 ? 4 : 1,
                  getTitlesWidget: (valor, meta) {
                    final rotulo = periodoDias == 1
                        ? '${valor.toInt().toString().padLeft(2, '0')}:00'
                        : const ['Seg', 'Ter', 'Qua', 'Qui', 'Sex', 'Sáb', 'Dom'][valor.toInt().clamp(0, 6).toInt()];
                    return Padding(padding: const EdgeInsets.only(top: 7), child: Text(rotulo, style: const TextStyle(fontSize: 9, color: CoresHortasmart.textoSecundario)));
                  },
                )),
              ),
              lineTouchData: LineTouchData(
                handleBuiltInTouches: true,
                touchTooltipData: LineTouchTooltipData(
                  getTooltipItems: (spots) => spots.map((spot) => LineTooltipItem(
                    '${spot.y.toStringAsFixed(0)}%',
                    const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 11),
                  )).toList(),
                ),
              ),
              lineBarsData: List.generate(_series.length, (indice) => LineChartBarData(
                spots: _series[indice],
                isCurved: true,
                curveSmoothness: 0.24,
                color: _cores[indice],
                barWidth: 2.5,
                isStrokeCapRound: true,
                dotData: const FlDotData(show: false),
                belowBarData: BarAreaData(show: false),
              )),
            ),
          ),
        ),
        const SizedBox(height: 13),
        Wrap(
          spacing: 16,
          runSpacing: 9,
          children: List.generate(_nomes.length, (indice) => Row(mainAxisSize: MainAxisSize.min, children: [
            Container(width: 8, height: 8, decoration: BoxDecoration(color: _cores[indice], shape: BoxShape.circle)),
            const SizedBox(width: 6),
            Text(_nomes[indice], style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: CoresHortasmart.textoSecundario)),
          ])),
        ),
      ]),
    );
  }
}

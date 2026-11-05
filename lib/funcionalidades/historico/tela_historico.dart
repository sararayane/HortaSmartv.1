import 'package:flutter/material.dart';

import '../../compartilhado/componentes/area_pagina.dart';
import '../../compartilhado/componentes/aviso_demonstracao.dart';
import '../../compartilhado/componentes/etiqueta_status.dart';
import '../../compartilhado/componentes/indicador_umidade.dart';
import '../../compartilhado/componentes/titulo_secao.dart';
import '../../compartilhado/constantes/cores.dart';
import '../../dados/modelos/canteiro.dart';
import 'grafico_umidade.dart';

class TelaHistorico extends StatefulWidget {
  const TelaHistorico({super.key, required this.canteiros});
  final List<Canteiro> canteiros;

  @override
  State<TelaHistorico> createState() => _TelaHistoricoState();
}

class _TelaHistoricoState extends State<TelaHistorico> {
  int _periodoDias = 1;
  String _tipoGrafico = 'Umidade';

  @override
  Widget build(BuildContext context) {
    final acionamentos = _periodoDias == 1 ? 6 : 31;
    final litros = _periodoDias == 1 ? 48 : 263;

    return AreaPagina(
      child: SingleChildScrollView(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const AvisoDemonstracao(texto: 'Histórico e consumo são exemplos visuais; os registros reais virão do Firebase após a integração.'),
          const SizedBox(height: 16),
          Row(children: [
            Expanded(child: Text('Resumo do período', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900, color: CoresHortasmart.texto))),
            SegmentedButton<int>(
              segments: const [ButtonSegment(value: 1, label: Text('24 h')), ButtonSegment(value: 7, label: Text('7 dias'))],
              selected: {_periodoDias},
              showSelectedIcon: false,
              onSelectionChanged: (valores) => setState(() => _periodoDias = valores.first),
              style: const ButtonStyle(visualDensity: VisualDensity.compact, textStyle: WidgetStatePropertyAll(TextStyle(fontSize: 11, fontWeight: FontWeight.w700))),
            ),
          ]),
          const SizedBox(height: 12),
          LayoutBuilder(builder: (context, constraints) {
            final cardWidth = (constraints.maxWidth - 12) / 2;
            return Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                SizedBox(width: cardWidth, child: _CartaoResumo(rotulo: 'Água consumida', valor: '$litros L', detalhe: 'Estimativa do período', icone: Icons.water_drop_rounded, cor: CoresHortasmart.azul, fundo: const Color(0xFFE8F4FD))),
                SizedBox(width: cardWidth, child: _CartaoResumo(rotulo: 'Acionamentos da bomba', valor: '$acionamentos vezes', detalhe: _periodoDias == 1 ? 'Nas últimas 24 horas' : 'Nos últimos 7 dias', icone: Icons.water_drop_rounded, cor: CoresHortasmart.verdeEscuro, fundo: CoresHortasmart.verdeClaro)),
              ],
            );
          }),
          const SizedBox(height: 22),
          const TituloSecao(titulo: 'Histórico por indicador', detalhe: 'Dados demonstrativos'),
          const SizedBox(height: 11),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: SegmentedButton<String>(
              segments: const [
                ButtonSegment(value: 'Umidade', label: Text('Umidade do solo'), icon: Icon(Icons.opacity_rounded)),
                ButtonSegment(value: 'Bomba', label: Text('Bomba'), icon: Icon(Icons.water_drop_outlined)),
                ButtonSegment(value: 'Água', label: Text('Consumo de água'), icon: Icon(Icons.water_drop_outlined)),
              ],
              selected: {_tipoGrafico},
              showSelectedIcon: false,
              onSelectionChanged: (valores) => setState(() => _tipoGrafico = valores.first),
              style: const ButtonStyle(visualDensity: VisualDensity.compact, textStyle: WidgetStatePropertyAll(TextStyle(fontSize: 11, fontWeight: FontWeight.w700))),
            ),
          ),
          const SizedBox(height: 12),
          if (_tipoGrafico == 'Umidade')
            GraficoUmidade(periodoDias: _periodoDias)
          else
            _GraficoBarras(periodoDias: _periodoDias, mostrarAgua: _tipoGrafico == 'Água'),
          const SizedBox(height: 20),
          const TituloSecao(titulo: 'Resumo por canteiro'),
          const SizedBox(height: 10),
          if (widget.canteiros.isEmpty)
            const _CartaoVazio()
          else
            ...widget.canteiros.map((canteiro) => Padding(
              padding: const EdgeInsets.only(bottom: 9),
              child: _LinhaCanteiro(canteiro: canteiro, litros: _litrosPorCanteiro(canteiro)),
            )),
          const SizedBox(height: 11),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(color: const Color(0xFFF0F6F1), borderRadius: BorderRadius.circular(17)),
            child: const Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Icon(Icons.info_outline_rounded, color: CoresHortasmart.verde, size: 19),
              SizedBox(width: 9),
              Expanded(child: Text('A estimativa de litros usa a vazão da bomba multiplicada pelo tempo de funcionamento. Para melhorar a precisão, podemos medir a vazão ou instalar um sensor de fluxo.', style: TextStyle(fontSize: 11, color: CoresHortasmart.textoSecundario, height: 1.45))),
            ]),
          ),
          const SizedBox(height: 24),
        ]),
      ),
    );
  }

  int _litrosPorCanteiro(Canteiro canteiro) {
    switch (canteiro.cultura.toLowerCase()) {
      case 'alface': return _periodoDias == 1 ? 8 : 52;
      case 'tomate': return _periodoDias == 1 ? 14 : 78;
      case 'cenoura': return _periodoDias == 1 ? 12 : 64;
      default: return _periodoDias == 1 ? 14 : 69;
    }
  }
}

class _CartaoResumo extends StatelessWidget {
  const _CartaoResumo({required this.rotulo, required this.valor, required this.detalhe, required this.icone, required this.cor, required this.fundo});
  final String rotulo;
  final String valor;
  final String detalhe;
  final IconData icone;
  final Color cor;
  final Color fundo;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(19), border: Border.all(color: const Color(0xFFE6ECE7))),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Container(width: 37, height: 37, decoration: BoxDecoration(color: fundo, borderRadius: BorderRadius.circular(12)), child: Icon(icone, color: cor, size: 21)),
          const Spacer(),
          const Icon(Icons.more_horiz_rounded, color: Color(0xFF9AA79D), size: 20),
        ]),
        const SizedBox(height: 12),
        Text(rotulo, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 11, height: 1.25, fontWeight: FontWeight.w700, color: CoresHortasmart.textoSecundario)),
        const SizedBox(height: 4),
        FittedBox(alignment: Alignment.centerLeft, fit: BoxFit.scaleDown, child: Text(valor, style: TextStyle(fontSize: 23, height: 1.1, fontWeight: FontWeight.w900, letterSpacing: -0.6, color: cor))),
        const SizedBox(height: 4),
        Text(detalhe, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 10, color: CoresHortasmart.textoSecundario)),
      ]),
    );
  }
}

class _GraficoBarras extends StatelessWidget {
  const _GraficoBarras({required this.periodoDias, required this.mostrarAgua});
  final int periodoDias;
  final bool mostrarAgua;

  @override
  Widget build(BuildContext context) {
    final valores = mostrarAgua
        ? (periodoDias == 1 ? [3, 7, 4, 9, 6, 11, 8] : [32, 41, 38, 46, 35, 52, 48])
        : (periodoDias == 1 ? [0, 1, 0, 2, 1, 1, 1] : [3, 5, 4, 6, 3, 5, 5]);
    final rotulos = periodoDias == 1 ? const ['00h', '04h', '08h', '12h', '16h', '20h', '24h'] : const ['Seg', 'Ter', 'Qua', 'Qui', 'Sex', 'Sáb', 'Dom'];
    final maximo = valores.reduce((a, b) => a > b ? a : b).toDouble();
    final cor = mostrarAgua ? CoresHortasmart.azul : CoresHortasmart.verde;

    return Container(
      padding: const EdgeInsets.fromLTRB(15, 17, 15, 14),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), border: Border.all(color: const Color(0xFFE6ECE7))),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(mostrarAgua ? 'Consumo de água por intervalo' : 'Acionamentos da bomba por intervalo', style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 14, color: CoresHortasmart.texto)),
        const SizedBox(height: 4),
        Text(mostrarAgua ? 'Litros estimados · exemplo' : 'Quantidade de acionamentos · exemplo', style: const TextStyle(fontSize: 11, color: CoresHortasmart.textoSecundario)),
        const SizedBox(height: 20),
        SizedBox(
          height: 190,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: List.generate(valores.length, (indice) {
              final altura = (valores[indice] / (maximo == 0 ? 1 : maximo)) * 118;
              return Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Text('${valores[indice]}', style: const TextStyle(fontSize: 10, color: CoresHortasmart.textoSecundario, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 6),
                    Expanded(
                      child: Align(
                        alignment: Alignment.bottomCenter,
                        child: Container(
                          width: 19,
                          height: altura.clamp(4, 118).toDouble(),
                          decoration: BoxDecoration(color: cor.withOpacity(0.88), borderRadius: const BorderRadius.vertical(top: Radius.circular(7))),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(rotulos[indice], style: const TextStyle(fontSize: 9, color: CoresHortasmart.textoSecundario)),
                  ],
                ),
              );
            }),
          ),
        ),
      ]),
    );
  }
}

class _LinhaCanteiro extends StatelessWidget {
  const _LinhaCanteiro({required this.canteiro, required this.litros});
  final Canteiro canteiro;
  final int litros;

  String get _emoji {
    switch (canteiro.cultura.toLowerCase()) {
      case 'alface': return '🥬';
      case 'tomate': return '🍅';
      case 'cenoura': return '🥕';
      case 'rúcula':
      case 'rucula': return '🌿';
      default: return '🌱';
    }
  }

  @override
  Widget build(BuildContext context) {
    final estado = classificarUmidade(canteiro.umidadeAtual);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 11),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: const Color(0xFFE6ECE7))),
      child: Row(children: [
        Container(width: 42, height: 42, alignment: Alignment.center, decoration: BoxDecoration(color: CoresHortasmart.verdeClaro, borderRadius: BorderRadius.circular(13)), child: Text(_emoji, style: const TextStyle(fontSize: 24))),
        const SizedBox(width: 10),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(canteiro.cultura, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: CoresHortasmart.texto)),
          const SizedBox(height: 3),
          Text('Umidade média: ${canteiro.umidadeAtual.round()}%', style: const TextStyle(fontSize: 10, color: CoresHortasmart.textoSecundario)),
        ])),
        EtiquetaStatus(texto: estado.texto, cor: estado.cor, fundo: estado.fundo),
        const SizedBox(width: 10),
        Text('$litros L', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w900, color: CoresHortasmart.texto)),
      ]),
    );
  }
}

class _CartaoVazio extends StatelessWidget {
  const _CartaoVazio();
  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(18),
    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(18)),
    child: const Text('Cadastre um canteiro para consultar o histórico.', style: TextStyle(color: CoresHortasmart.textoSecundario)),
  );
}

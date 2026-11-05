import 'package:flutter/material.dart';

/// Cabeçalho compartilhado das quatro áreas principais do HortaSmart.
class CabecalhoAplicativo extends StatelessWidget {
  const CabecalhoAplicativo({
    super.key,
    required this.indiceSelecionado,
    required this.aoVoltarPainel,
    required this.aoAcionar,
  });

  final int indiceSelecionado;
  final VoidCallback aoVoltarPainel;
  final VoidCallback aoAcionar;

  static const _titulos = [
    'HortaSmart',
    'Irrigação',
    'Histórico',
    'Configurações',
  ];

  static const _subtitulos = [
    'Irrigação inteligente',
    'Controle de irrigação por canteiro',
    'Leituras e consumo de água',
    'Canteiros, dispositivos e sensores',
  ];

  static const _iconesAcao = [
    Icons.notifications_none_rounded,
    Icons.tune_rounded,
    Icons.calendar_month_outlined,
    Icons.info_outline_rounded,
  ];

  @override
  Widget build(BuildContext context) {
    final indice = indiceSelecionado.clamp(0, _titulos.length - 1).toInt();

    final painel = indice == 0;
    final largura = MediaQuery.sizeOf(context).width;

    final tablet = largura >= 600 && largura < 1100;
    final computador = largura >= 1100;

    final tamanhoTitulo = computador
        ? (painel ? 30.0 : 28.0)
        : tablet
            ? (painel ? 28.0 : 26.0)
            : (painel ? 24.0 : 22.0);

    final tamanhoSubtitulo = computador
        ? 16.0
        : tablet
            ? 15.0
            : 13.0;

    final tamanhoIcone = computador
        ? 28.0
        : tablet
            ? 27.0
            : 25.0;

    final tamanhoLogo = computador
        ? 54.0
        : tablet
            ? 50.0
            : 44.0;

    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF087B4B),
            Color(0xFF05643D),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: Color(0x17052F1D),
            blurRadius: 14,
            offset: Offset(0, 4),
          ),
        ],
      ),
      padding: EdgeInsets.symmetric(
        horizontal: computador
            ? 28
            : tablet
                ? 24
                : 16,
        vertical: computador
            ? 17
            : tablet
                ? 16
                : 12,
      ),
      child: Row(
        children: [
          if (painel) ...[
            Container(
              width: tamanhoLogo,
              height: tamanhoLogo,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.16),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.18),
                ),
              ),
              child: Icon(
                Icons.eco_rounded,
                color: Colors.white,
                size: tamanhoIcone,
              ),
            ),
            const SizedBox(width: 12),
          ] else ...[
            IconButton(
              onPressed: aoVoltarPainel,
              tooltip: 'Voltar ao painel',
              visualDensity: VisualDensity.compact,
              icon: Icon(
                Icons.arrow_back_rounded,
                color: Colors.white,
                size: tamanhoIcone,
              ),
            ),
            const SizedBox(width: 4),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment:
                  painel ? CrossAxisAlignment.start : CrossAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _titulos[indice],
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: tamanhoTitulo,
                    height: 1.15,
                    letterSpacing: painel ? -0.5 : 0,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _subtitulos[indice],
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  textAlign: painel ? TextAlign.start : TextAlign.center,
                  style: TextStyle(
                    color: const Color(0xFFD6F0E1),
                    fontSize: tamanhoSubtitulo,
                    height: 1.2,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 9),
          IconButton(
            onPressed: aoAcionar,
            tooltip: switch (indice) {
              0 => 'Notificações',
              1 => 'Abrir configurações',
              2 => 'Período do histórico',
              _ => 'Sobre o aplicativo',
            },
            visualDensity: VisualDensity.compact,
            icon: Icon(
              _iconesAcao[indice],
              color: Colors.white,
              size: tamanhoIcone,
            ),
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';

/// Cabeçalho compartilhado das quatro áreas principais do HortaSmart.
/// Mantém notificações e acesso à conta disponíveis em todas as páginas.
class CabecalhoAplicativo extends StatelessWidget {
  const CabecalhoAplicativo({
    super.key,
    required this.indiceSelecionado,
    required this.nomeUsuario,
    required this.emailUsuario,
    required this.aoAbrirNotificacoes,
    required this.aoAbrirPerfil,
    required this.aoAbrirConfiguracoes,
    required this.aoSair,
  });

  final int indiceSelecionado;
  final String nomeUsuario;
  final String emailUsuario;
  final VoidCallback aoAbrirNotificacoes;
  final VoidCallback aoAbrirPerfil;
  final VoidCallback aoAbrirConfiguracoes;
  final VoidCallback aoSair;

  static const _titulos = [
    'Painel principal',
    'Irrigação',
    'Histórico',
    'Configurações',
  ];

  static const _subtitulos = [
    'Acompanhe sua horta em um só lugar',
    'Gerencie a irrigação de cada canteiro',
    'Acompanhe leituras e consumo de água',
    'Gerencie canteiros, dispositivos e sensores',
  ];

  @override
  Widget build(BuildContext context) {
    final indice = indiceSelecionado.clamp(0, _titulos.length - 1).toInt();
    final largura = MediaQuery.sizeOf(context).width;
    final tablet = largura >= 600 && largura < 1100;
    final computador = largura >= 1100;

    final tamanhoTitulo =
        computador
            ? 25.0
            : tablet
            ? 23.0
            : 20.0;
    final tamanhoSubtitulo =
        computador
            ? 14.0
            : tablet
            ? 13.0
            : 11.5;
    final tamanhoIcone =
        computador
            ? 25.0
            : tablet
            ? 24.0
            : 22.0;
    final tamanhoLogo =
        computador
            ? 48.0
            : tablet
            ? 46.0
            : 42.0;

    final nome =
        nomeUsuario.trim().isEmpty ? 'Minha conta' : nomeUsuario.trim();
    final inicial = nome.substring(0, 1).toUpperCase();

    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF087B4B), Color(0xFF05643D)],
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
        horizontal:
            computador
                ? 28
                : tablet
                ? 22
                : 14,
        vertical:
            computador
                ? 15
                : tablet
                ? 14
                : 11,
      ),
      child: Row(
        children: [
          Container(
            width: tamanhoLogo,
            height: tamanhoLogo,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.16),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.white.withValues(alpha: 0.18)),
            ),
            child: Icon(
              Icons.eco_rounded,
              color: Colors.white,
              size: tamanhoIcone,
            ),
          ),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
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
                    letterSpacing: -0.35,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _subtitulos[indice],
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
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
          const SizedBox(width: 5),
          IconButton(
            onPressed: aoAbrirNotificacoes,
            tooltip: 'Notificações',
            visualDensity: VisualDensity.compact,
            constraints: const BoxConstraints.tightFor(width: 42, height: 42),
            padding: EdgeInsets.zero,
            icon: Icon(
              Icons.notifications_none_rounded,
              color: Colors.white,
              size: tamanhoIcone,
            ),
          ),
          const SizedBox(width: 5),
          PopupMenuButton<_AcaoPerfil>(
            tooltip: 'Menu da conta',
            onSelected: (acao) {
              switch (acao) {
                case _AcaoPerfil.perfil:
                  aoAbrirPerfil();
                  break;
                case _AcaoPerfil.configuracoes:
                  aoAbrirConfiguracoes();
                  break;
                case _AcaoPerfil.sair:
                  aoSair();
                  break;
              }
            },
            offset: const Offset(0, 48),
            color: Colors.white,
            surfaceTintColor: Colors.white,
            elevation: 9,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            itemBuilder:
                (context) => [
                  PopupMenuItem<_AcaoPerfil>(
                    enabled: false,
                    height: 66,
                    child: SizedBox(
                      width: 220,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            nome,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Color(0xFF183D2C),
                              fontWeight: FontWeight.w800,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            emailUsuario.trim().isEmpty
                                ? 'Conta HortaSmart'
                                : emailUsuario.trim(),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Color(0xFF718078),
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const PopupMenuDivider(height: 1),
                  const PopupMenuItem<_AcaoPerfil>(
                    value: _AcaoPerfil.perfil,
                    child: _ItemMenuConta(
                      icone: Icons.person_outline_rounded,
                      texto: 'Meu perfil',
                    ),
                  ),
                  const PopupMenuItem<_AcaoPerfil>(
                    value: _AcaoPerfil.configuracoes,
                    child: _ItemMenuConta(
                      icone: Icons.settings_outlined,
                      texto: 'Configurações',
                    ),
                  ),
                  const PopupMenuDivider(height: 1),
                  const PopupMenuItem<_AcaoPerfil>(
                    value: _AcaoPerfil.sair,
                    child: _ItemMenuConta(
                      icone: Icons.logout_rounded,
                      texto: 'Sair da conta',
                      cor: Color(0xFFB42318),
                    ),
                  ),
                ],
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.18),
                shape: BoxShape.circle,
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.65),
                  width: 1.3,
                ),
              ),
              alignment: Alignment.center,
              child: Text(
                inicial,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

enum _AcaoPerfil { perfil, configuracoes, sair }

class _ItemMenuConta extends StatelessWidget {
  const _ItemMenuConta({
    required this.icone,
    required this.texto,
    this.cor = const Color(0xFF34483D),
  });

  final IconData icone;
  final String texto;
  final Color cor;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icone, size: 19, color: cor),
        const SizedBox(width: 11),
        Text(
          texto,
          style: TextStyle(
            color: cor,
            fontWeight: FontWeight.w600,
            fontSize: 13,
          ),
        ),
      ],
    );
  }
}

import 'package:flutter/material.dart';

import 'tela_login.dart';

class TelaAbertura extends StatefulWidget {
  const TelaAbertura({super.key});

  @override
  State<TelaAbertura> createState() => _TelaAberturaState();
}

class _TelaAberturaState extends State<TelaAbertura>
    with SingleTickerProviderStateMixin {
  // CORES

  static const Color _verde = Color(0xFF087443);
  static const Color _verdeEscuro = Color(0xFF064D31);
  static const Color _verdeClaro = Color(0xFFE5F1E8);
  static const Color _textoSecundario = Color(0xFF64746A);

  // IMAGEM DE FUNDO

  static const String _imagemFundo = 'assets/images/cultivo.png';

  static const double _larguraMaxima = 560;

  // ANIMAÇÕES

  late final AnimationController _controlador;

  late final Animation<double> _animacaoIdentidade;
  late final Animation<double> _animacaoDestaques;
  late final Animation<double> _animacaoCarregamento;
  late final Animation<double> _animacaoRodape;

  bool _navegandoParaLogin = false;

  @override
  void initState() {
    super.initState();

    _controlador = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 5),
    );

    _animacaoIdentidade = _criarAnimacao(0.00, 0.32);
    _animacaoDestaques = _criarAnimacao(0.18, 0.53);
    _animacaoCarregamento = _criarAnimacao(0.38, 0.75);
    _animacaoRodape = _criarAnimacao(0.65, 0.95);

    _controlador.addStatusListener(_aoFinalizarAbertura);

    _controlador.forward();
  }

  // TRANSIÇÃO PARA A TELA DE LOGIN

  void _aoFinalizarAbertura(AnimationStatus status) {
    if (status != AnimationStatus.completed ||
        _navegandoParaLogin ||
        !mounted) {
      return;
    }

    _navegandoParaLogin = true;

    Navigator.of(context).push(
      PageRouteBuilder<void>(
        pageBuilder: (
          context,
          animation,
          secondaryAnimation,
        ) {
          return const TelaLogin();
        },

        // DURAÇÃO DA TRANSIÇÃO

        transitionDuration: const Duration(milliseconds: 700),

        reverseTransitionDuration: const Duration(milliseconds: 450),

        // EFEITO DE DISSOLUÇÃO

        transitionsBuilder: (
          context,
          animation,
          secondaryAnimation,
          child,
        ) {
          final curva = CurvedAnimation(
            parent: animation,
            curve: Curves.easeInOutCubic,
          );

          return FadeTransition(
            opacity: curva,
            child: SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0, 0.015),
                end: Offset.zero,
              ).animate(curva),
              child: child,
            ),
          );
        },
      ),
    );
  }

  Animation<double> _criarAnimacao(
    double inicio,
    double fim,
  ) {
    return CurvedAnimation(
      parent: _controlador,
      curve: Interval(
        inicio,
        fim,
        curve: Curves.easeOutCubic,
      ),
    );
  }

  @override
  void dispose() {
    _controlador.removeStatusListener(
      _aoFinalizarAbertura,
    );

    _controlador.dispose();

    super.dispose();
  }

  // ANIMAÇÃO DOS ELEMENTOS

  Widget _entradaAnimada({
    required Animation<double> animacao,
    required Widget child,
  }) {
    return FadeTransition(
      opacity: animacao,
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, 0.04),
          end: Offset.zero,
        ).animate(animacao),
        child: child,
      ),
    );
  }

  // TELA PRINCIPAL

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3F9F1),
      body: Stack(
        fit: StackFit.expand,
        children: [
          // IMAGEM DE FUNDO

          Image.asset(
            _imagemFundo,
            fit: BoxFit.cover,
            alignment: Alignment.center,
            errorBuilder: (context, error, stackTrace) {
              return const DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Color(0xFFFCFEFC),
                      Color(0xFFDDEFD9),
                    ],
                  ),
                ),
              );
            },
          ),

          // CAMADA DE LEITURA

          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                stops: [0.0, 0.35, 0.68, 1.0],
                colors: [
                  Color(0xBFFFFFFF),
                  Color(0x22F7FFF2),
                  Color(0x18F4FFEA),
                  Color(0xBFF3FAEF),
                ],
              ),
            ),
          ),

          // CONTEÚDO RESPONSIVO

          SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final largura = constraints.maxWidth;
                final altura = constraints.maxHeight;

                final compacto = largura < 380 || altura < 680;

                final paddingHorizontal = largura < 360 ? 18.0 : 26.0;

                final paddingVertical = compacto ? 12.0 : 20.0;

                final alturaConteudo = (altura - paddingVertical * 2)
                    .clamp(0.0, double.infinity)
                    .toDouble();

                final larguraConteudo = (largura - paddingHorizontal * 2)
                    .clamp(0.0, _larguraMaxima)
                    .toDouble();

                return Center(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      maxWidth: larguraConteudo,
                    ),
                    child: SingleChildScrollView(
                      physics: const ClampingScrollPhysics(),
                      padding: EdgeInsets.symmetric(
                        horizontal: paddingHorizontal,
                        vertical: paddingVertical,
                      ),
                      child: ConstrainedBox(
                        constraints: BoxConstraints(
                          minHeight: alturaConteudo,
                        ),
                        child: SizedBox(
                          width: double.infinity,
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              _construirIdentidade(
                                compacto: compacto,
                              ),
                              _construirDestaques(
                                compacto: compacto,
                              ),
                              _construirParteInferior(
                                compacto: compacto,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // IDENTIDADE DO HORTASMART

  Widget _construirIdentidade({
    required bool compacto,
  }) {
    final tamanhoLogo = compacto ? 108.0 : 126.0;

    return _entradaAnimada(
      animacao: _animacaoIdentidade,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _construirLogo(
            tamanho: tamanhoLogo,
          ),
          SizedBox(height: compacto ? 17 : 23),
          Text.rich(
            const TextSpan(
              children: [
                TextSpan(
                  text: 'Horta',
                  style: TextStyle(
                    color: _verdeEscuro,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                TextSpan(
                  text: 'Smart',
                  style: TextStyle(
                    color: _verde,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: compacto ? 34 : 42,
              letterSpacing: -1.4,
              height: 1.1,
            ),
          ),
          const SizedBox(height: 10),
          const Text(
            'Regando para novas gerações.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: _textoSecundario,
              fontWeight: FontWeight.w500,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            'Tecnologia e cuidado em cada cultivo.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: compacto ? 12 : 14,
              color: _textoSecundario,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  // LOGO CIRCULAR

  Widget _construirLogo({
    required double tamanho,
  }) {
    final tamanhoSelo = tamanho * 0.34;

    return SizedBox(
      width: tamanho + 12,
      height: tamanho + 12,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            width: tamanho,
            height: tamanho,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withValues(alpha: 0.55),
              border: Border.all(
                color: const Color(0xFFD4E7D6),
                width: 1.5,
              ),
            ),
          ),
          Container(
            width: tamanho * 0.83,
            height: tamanho * 0.83,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFF15965B),
                  _verde,
                  _verdeEscuro,
                ],
              ),
              boxShadow: [
                BoxShadow(
                  color: _verde.withValues(alpha: 0.18),
                  blurRadius: 20,
                  offset: const Offset(0, 7),
                ),
              ],
            ),
            child: Icon(
              Icons.eco_rounded,
              color: Colors.white,
              size: tamanho * 0.42,
            ),
          ),
          Positioned(
            right: 0,
            bottom: 2,
            child: Container(
              width: tamanhoSelo,
              height: tamanhoSelo,
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                border: Border.all(
                  color: const Color(0xFFDCE9DE),
                  width: 1.2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: _verde.withValues(alpha: 0.12),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Icon(
                Icons.water_drop_rounded,
                color: _verde,
                size: tamanhoSelo * 0.48,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // DESTAQUES

  Widget _construirDestaques({
    required bool compacto,
  }) {
    return _entradaAnimada(
      animacao: _animacaoDestaques,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: _construirItemDestaque(
              icone: Icons.sensors_rounded,
              titulo: 'Cultivo monitorado',
              compacto: compacto,
            ),
          ),
          Expanded(
            child: _construirItemDestaque(
              icone: Icons.water_drop_rounded,
              titulo: 'Irrigação inteligente',
              compacto: compacto,
            ),
          ),
        ],
      ),
    );
  }

  // CÍRCULO DE CADA RECURSO

  Widget _construirItemDestaque({
    required IconData icone,
    required String titulo,
    required bool compacto,
  }) {
    final tamanhoCirculo = compacto ? 96.0 : 116.0;
    final tamanhoInterior = tamanhoCirculo * 0.78;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          width: tamanhoCirculo,
          height: tamanhoCirculo,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.94),
            shape: BoxShape.circle,
            border: Border.all(
              color: const Color(0xFFDCE9DE),
              width: 1.4,
            ),
            boxShadow: [
              BoxShadow(
                color: _verde.withValues(alpha: 0.12),
                blurRadius: 17,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Center(
            child: Container(
              width: tamanhoInterior,
              height: tamanhoInterior,
              decoration: BoxDecoration(
                color: _verdeClaro.withValues(alpha: 0.95),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icone,
                color: _verde,
                size: compacto ? 34 : 42,
              ),
            ),
          ),
        ),
        const SizedBox(height: 13),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 3),
          child: Text(
            titulo,
            textAlign: TextAlign.center,
            maxLines: 2,
            style: TextStyle(
              color: _verdeEscuro,
              fontSize: compacto ? 12 : 14,
              fontWeight: FontWeight.w700,
              height: 1.35,
            ),
          ),
        ),
      ],
    );
  }

  // PARTE INFERIOR

  Widget _construirParteInferior({
    required bool compacto,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _construirCarregamento(),
        SizedBox(height: compacto ? 24 : 34),
        _construirRodape(),
      ],
    );
  }

  // CARREGAMENTO

  Widget _construirCarregamento() {
    return _entradaAnimada(
      animacao: _animacaoCarregamento,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'Preparando sua experiência...',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              color: _textoSecundario,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: 220,
            child: AnimatedBuilder(
              animation: _controlador,
              builder: (context, child) {
                return Semantics(
                  label: 'Carregamento do HortaSmart',
                  value: '${(_controlador.value * 100).round()}%',
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: LinearProgressIndicator(
                      value: _controlador.value,
                      minHeight: 5,
                      backgroundColor: const Color(0xFFDCE9DE),
                      valueColor: const AlwaysStoppedAnimation<Color>(
                        _verde,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // RODAPÉ

  Widget _construirRodape() {
    return _entradaAnimada(
      animacao: _animacaoRodape,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 34,
            height: 3,
            decoration: BoxDecoration(
              color: const Color(0xFFBFD8C4),
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'HORTASMART • 2026',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 10,
              letterSpacing: 2,
              fontWeight: FontWeight.w700,
              color: Color(0xFF718076),
            ),
          ),
        ],
      ),
    );
  }
}

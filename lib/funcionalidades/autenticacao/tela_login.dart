import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../dados/servicos/servico_autenticacao.dart';
import 'tela_cadastro.dart';

class TelaLogin extends StatefulWidget {
  const TelaLogin({super.key, this.onEntrar});

  final Future<void> Function(String email, String senha)? onEntrar;

  @override
  State<TelaLogin> createState() => _TelaLoginState();
}

class _TelaLoginState extends State<TelaLogin> {
  // IDENTIDADE VISUAL

  static const Color _verde = Color(0xFF087443);
  static const Color _verdeEscuro = Color(0xFF064D31);
  static const Color _verdeClaro = Color(0xFFE5F1E8);
  static const Color _fundo = Color(0xFFF7FAF7);
  static const Color _textoSecundario = Color(0xFF718076);

  static const String _imagemLogo = 'assets/images/logo_hortasmart.png';

  // SERVIÇOS E FORMULÁRIO

  final _formulario = GlobalKey<FormState>();
  final _servicoAutenticacao = ServicoAutenticacao();

  final _emailController = TextEditingController();
  final _senhaController = TextEditingController();

  // ESTADOS

  bool _mostrarSenha = false;
  bool _lembrarDeMim = true;

  bool _carregando = false;
  bool _carregandoGoogle = false;
  bool _recuperandoSenha = false;

  bool get _ocupado => _carregando || _carregandoGoogle || _recuperandoSenha;

  @override
  void dispose() {
    _emailController.dispose();
    _senhaController.dispose();
    super.dispose();
  }

  // CONFIGURAÇÃO DE SESSÃO

  Future<void> _configurarPersistencia() async {
    if (!kIsWeb) return;

    await FirebaseAuth.instance.setPersistence(
      _lembrarDeMim ? Persistence.LOCAL : Persistence.SESSION,
    );
  }

  // MENSAGENS DE ERRO

  String _mensagemErro(Object erro) {
    if (erro is FirebaseAuthException) {
      switch (erro.code) {
        case 'email-nao-verificado':
          return 'Confirme seu e-mail antes de entrar.';

        case 'invalid-email':
          return 'O endereço de e-mail informado é inválido.';

        case 'user-disabled':
          return 'Esta conta está desativada.';

        case 'user-not-found':
        case 'wrong-password':
        case 'invalid-credential':
          return 'E-mail ou senha incorretos.';

        case 'too-many-requests':
          return 'Muitas tentativas. Aguarde um pouco.';

        case 'network-request-failed':
          return 'Verifique sua conexão com a internet.';

        case 'operation-not-allowed':
          return 'Este método de acesso não está habilitado no Firebase.';

        case 'account-exists-with-different-credential':
          return 'Já existe uma conta com este e-mail usando outro método de acesso.';

        case 'popup-closed-by-user':
          return 'A janela de acesso do Google foi fechada.';

        case 'google-token-ausente':
          return 'Não foi possível obter a credencial do Google.';

        default:
          return 'Não foi possível realizar o acesso. Tente novamente.';
      }
    }

    return 'Ocorreu um erro. Verifique sua conexão e tente novamente.';
  }

  void _mostrarMensagem(String mensagem, {bool erro = false}) {
    if (!mounted) return;

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(mensagem),
          backgroundColor: erro ? Colors.red.shade700 : _verde,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
  }

  // FINALIZA O ACESSO

  void _finalizarAcesso() {
    Navigator.of(context).popUntil((rota) => rota.isFirst);
  }

  // LOGIN COM E-MAIL E SENHA

  Future<void> _entrar() async {
    if (_ocupado) return;

    if (_formulario.currentState?.validate() != true) {
      return;
    }

    setState(() {
      _carregando = true;
    });

    try {
      await _configurarPersistencia();

      if (widget.onEntrar != null) {
        await widget.onEntrar!(
          _emailController.text.trim(),
          _senhaController.text,
        );
      } else {
        await _servicoAutenticacao.entrar(
          email: _emailController.text.trim(),
          senha: _senhaController.text,
        );
      }

      if (!mounted) return;

      _finalizarAcesso();
    } catch (erro) {
      _mostrarMensagem(_mensagemErro(erro), erro: true);
    } finally {
      if (mounted) {
        setState(() {
          _carregando = false;
        });
      }
    }
  }

  // LOGIN COM GOOGLE

  Future<void> _entrarComGoogle() async {
    if (_ocupado) return;

    setState(() {
      _carregandoGoogle = true;
    });

    try {
      await _configurarPersistencia();

      await _servicoAutenticacao.entrarComGoogle();

      if (!mounted) return;

      _finalizarAcesso();
    } catch (erro) {
      _mostrarMensagem(_mensagemErro(erro), erro: true);
    } finally {
      if (mounted) {
        setState(() {
          _carregandoGoogle = false;
        });
      }
    }
  }

  // RECUPERAÇÃO DE SENHA

  Future<void> _recuperarSenha() async {
    if (_ocupado) return;

    final controladorEmail = TextEditingController(
      text: _emailController.text.trim(),
    );

    final email = await showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(22),
          ),
          title: const Text(
            'Recuperar senha',
            style: TextStyle(color: _verdeEscuro, fontWeight: FontWeight.bold),
          ),
          content: TextField(
            controller: controladorEmail,
            keyboardType: TextInputType.emailAddress,
            autofocus: true,
            decoration: InputDecoration(
              hintText: 'seuemail@exemplo.com',
              prefixIcon: const Icon(Icons.email_outlined, color: _verde),
              filled: true,
              fillColor: const Color(0xFFF7F9F7),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text(
                'Cancelar',
                style: TextStyle(color: _textoSecundario),
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: _verde,
                foregroundColor: Colors.white,
              ),
              onPressed: () {
                final valor = controladorEmail.text.trim();

                if (valor.isEmpty ||
                    !RegExp(r'^[^@]+@[^@]+\.[^@]+$').hasMatch(valor)) {
                  return;
                }

                Navigator.pop(context, valor);
              },
              child: const Text('Enviar'),
            ),
          ],
        );
      },
    );

    controladorEmail.dispose();

    if (email == null || !mounted) return;

    setState(() {
      _recuperandoSenha = true;
    });

    try {
      await _servicoAutenticacao.recuperarSenha(email);

      _mostrarMensagem(
        'Se o endereço estiver cadastrado, você receberá as instruções por e-mail.',
      );
    } catch (erro) {
      _mostrarMensagem(_mensagemErro(erro), erro: true);
    } finally {
      if (mounted) {
        setState(() {
          _recuperandoSenha = false;
        });
      }
    }
  }

  // ABRIR CADASTRO

  void _abrirCadastro() {
    if (_ocupado) return;

    Navigator.push(
      context,
      MaterialPageRoute<void>(builder: (_) => const TelaCadastro()),
    );
  }

  // DECORAÇÃO DOS CAMPOS

  InputDecoration _decoracaoCampo({
    required String dica,
    required IconData icone,
    Widget? sufixo,
  }) {
    return InputDecoration(
      hintText: dica,
      hintStyle: const TextStyle(fontSize: 14, color: Color(0xFF9AA69D)),
      prefixIcon: Icon(icone, color: _verdeEscuro, size: 21),
      suffixIcon: sufixo,
      filled: true,
      fillColor: Colors.white.withValues(alpha: 0.94),
      contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 17),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(30),
        borderSide: const BorderSide(color: Color(0xFFD8E2D9)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(30),
        borderSide: const BorderSide(color: Color(0xFFD8E2D9)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(30),
        borderSide: const BorderSide(color: _verde, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(30),
        borderSide: const BorderSide(color: Colors.redAccent),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(30),
        borderSide: const BorderSide(color: Colors.redAccent, width: 1.5),
      ),
    );
  }

  // RÓTULO DOS CAMPOS

  Widget _construirRotulo(String texto) {
    return Padding(
      padding: const EdgeInsets.only(left: 3, bottom: 9),
      child: Text(
        texto,
        style: const TextStyle(
          color: _verdeEscuro,
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  // CAMPO DE E-MAIL

  Widget _construirCampoEmail() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _construirRotulo('E-mail'),
        TextFormField(
          controller: _emailController,
          keyboardType: TextInputType.emailAddress,
          textInputAction: TextInputAction.next,
          autofillHints: const [AutofillHints.email],
          autocorrect: false,
          enabled: !_ocupado,
          decoration: _decoracaoCampo(
            dica: 'seuemail@exemplo.com',
            icone: Icons.email_outlined,
          ),
          validator: (valor) {
            if (valor == null || valor.trim().isEmpty) {
              return 'Informe seu e-mail.';
            }

            if (!RegExp(r'^[^@]+@[^@]+\.[^@]+$').hasMatch(valor.trim())) {
              return 'Informe um e-mail válido.';
            }

            return null;
          },
        ),
      ],
    );
  }

  // CAMPO DE SENHA

  Widget _construirCampoSenha() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _construirRotulo('Senha'),
        TextFormField(
          controller: _senhaController,
          obscureText: !_mostrarSenha,
          textInputAction: TextInputAction.done,
          autofillHints: const [AutofillHints.password],
          enabled: !_ocupado,
          onFieldSubmitted: (_) => _entrar(),
          decoration: _decoracaoCampo(
            dica: 'Digite sua senha',
            icone: Icons.lock_outline_rounded,
            sufixo: IconButton(
              tooltip: _mostrarSenha ? 'Ocultar senha' : 'Mostrar senha',
              onPressed:
                  _ocupado
                      ? null
                      : () {
                        setState(() {
                          _mostrarSenha = !_mostrarSenha;
                        });
                      },
              icon: Icon(
                _mostrarSenha
                    ? Icons.visibility_off_outlined
                    : Icons.visibility_outlined,
                color: _verdeEscuro,
                size: 21,
              ),
            ),
          ),
          validator: (valor) {
            if (valor == null || valor.isEmpty) {
              return 'Informe sua senha.';
            }

            return null;
          },
        ),
      ],
    );
  }

  // LEMBRAR DE MIM E ESQUECI A SENHA

  Widget _construirOpcoes() {
    return Row(
      children: [
        Expanded(
          child: InkWell(
            onTap:
                _ocupado
                    ? null
                    : () {
                      setState(() {
                        _lembrarDeMim = !_lembrarDeMim;
                      });
                    },
            borderRadius: BorderRadius.circular(8),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Checkbox(
                  value: _lembrarDeMim,
                  activeColor: _verde,
                  visualDensity: VisualDensity.compact,
                  onChanged:
                      _ocupado
                          ? null
                          : (valor) {
                            setState(() {
                              _lembrarDeMim = valor ?? false;
                            });
                          },
                ),
                const Flexible(
                  child: Text(
                    'Lembrar de mim',
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: _verdeEscuro,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        TextButton(
          onPressed: _ocupado ? null : _recuperarSenha,
          style: TextButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            minimumSize: Size.zero,
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
          child: const Text(
            'Esqueci a senha',
            style: TextStyle(
              color: _verde,
              fontSize: 12,
              fontWeight: FontWeight.w700,
              decoration: TextDecoration.underline,
              decorationColor: _verde,
            ),
          ),
        ),
      ],
    );
  }

  // BOTÃO ENTRAR

  Widget _construirBotaoEntrar() {
    return SizedBox(
      width: double.infinity,
      height: 55,
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
            colors: [Color(0xFF55BB55), Color(0xFF13A64B)],
          ),
          borderRadius: BorderRadius.circular(30),
          boxShadow: [
            BoxShadow(
              color: _verde.withValues(alpha: 0.20),
              blurRadius: 14,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: ElevatedButton(
          onPressed: _ocupado ? null : _entrar,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.transparent,
            disabledBackgroundColor: Colors.transparent,
            foregroundColor: Colors.white,
            shadowColor: Colors.transparent,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(30),
            ),
          ),
          child:
              _carregando
                  ? const SizedBox(
                    width: 23,
                    height: 23,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2.3,
                    ),
                  )
                  : const Text(
                    'Entrar',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.2,
                    ),
                  ),
        ),
      ),
    );
  }

  // DIVISOR

  Widget _construirDivisor() {
    return Row(
      children: [
        const Expanded(child: Divider(color: Color(0xFFCAD9CD), thickness: 1)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 13),
          child: Text(
            'ou continue com',
            style: TextStyle(
              color: _textoSecundario.withValues(alpha: 0.9),
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        const Expanded(child: Divider(color: Color(0xFFCAD9CD), thickness: 1)),
      ],
    );
  }

  // BOTÃO GOOGLE

  Widget _construirBotaoGoogle() {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: OutlinedButton(
        onPressed: _ocupado ? null : _entrarComGoogle,
        style: OutlinedButton.styleFrom(
          backgroundColor: Colors.white.withValues(alpha: 0.92),
          foregroundColor: const Color(0xFF303A33),
          side: const BorderSide(color: Color(0xFFD8E2D9), width: 1.1),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30),
          ),
        ),
        child:
            _carregandoGoogle
                ? const SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                    color: _verde,
                    strokeWidth: 2,
                  ),
                )
                : const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    Text(
                      'G',
                      style: TextStyle(
                        color: Color(0xFF4285F4),
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    SizedBox(width: 11),
                    Text(
                      'Continuar com Google',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
      ),
    );
  }

  // LINK PARA CADASTRO

  Widget _construirCadastro() {
    return Wrap(
      alignment: WrapAlignment.center,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        const Text(
          'Não tem uma conta? ',
          style: TextStyle(color: _textoSecundario, fontSize: 13),
        ),
        GestureDetector(
          onTap: _ocupado ? null : _abrirCadastro,
          child: const Text(
            'Registre-se aqui',
            style: TextStyle(
              color: _verde,
              fontSize: 13,
              fontWeight: FontWeight.w700,
              decoration: TextDecoration.underline,
              decorationColor: _verde,
            ),
          ),
        ),
      ],
    );
  }

  // LOGO

  Widget _construirLogo() {
    return Image.asset(
      _imagemLogo,
      width: 76,
      height: 76,
      fit: BoxFit.contain,
      errorBuilder: (context, error, stackTrace) {
        return Container(
          width: 76,
          height: 76,
          decoration: BoxDecoration(
            color: _verdeClaro,
            shape: BoxShape.circle,
            border: Border.all(color: const Color(0xFFD5E7D8)),
          ),
          child: const Icon(Icons.eco_rounded, color: _verde, size: 43),
        );
      },
    );
  }

  // INTERFACE PRINCIPAL

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _fundo,
      body: Stack(
        children: [
          // FORMAS DECORATIVAS DE FUNDO

          Positioned(
            top: -100,
            right: -90,
            child: Container(
              width: 260,
              height: 260,
              decoration: BoxDecoration(
                color: _verde.withValues(alpha: 0.045),
                shape: BoxShape.circle,
              ),
            ),
          ),
          Positioned(
            bottom: -100,
            left: -90,
            child: Container(
              width: 260,
              height: 260,
              decoration: BoxDecoration(
                color: const Color(0xFF94CA91).withValues(alpha: 0.10),
                shape: BoxShape.circle,
              ),
            ),
          ),

          // CONTEÚDO RESPONSIVO
          SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final larguraConteudo =
                    (constraints.maxWidth - 40).clamp(0.0, 430.0).toDouble();

                final alturaMinima =
                    (constraints.maxHeight - 32)
                        .clamp(0.0, double.infinity)
                        .toDouble();

                return SingleChildScrollView(
                  physics: const ClampingScrollPhysics(),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 16,
                  ),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(minHeight: alturaMinima),
                    child: Center(
                      child: SizedBox(
                        width: larguraConteudo,
                        child: Form(
                          key: _formulario,
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              // CABEÇALHO

                              Center(child: _construirLogo()),

                              const SizedBox(height: 17),

                              const Text(
                                'Entre para acessar o',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 23,
                                  height: 1.3,
                                  color: Color(0xFF263B2E),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),

                              const SizedBox(height: 2),

                              const Text(
                                'HortaSmart',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 29,
                                  color: _verdeEscuro,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: -0.8,
                                ),
                              ),

                              const SizedBox(height: 9),

                              const Text(
                                'Acompanhe seus canteiros e controle a irrigação.',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 13,
                                  color: _textoSecundario,
                                  height: 1.5,
                                ),
                              ),

                              const SizedBox(height: 34),

                              // E-MAIL
                              _construirCampoEmail(),

                              const SizedBox(height: 21),

                              // SENHA
                              _construirCampoSenha(),

                              const SizedBox(height: 8),

                              // OPÇÕES
                              _construirOpcoes(),

                              const SizedBox(height: 19),

                              // ENTRAR
                              _construirBotaoEntrar(),

                              const SizedBox(height: 24),

                              // DIVISOR
                              _construirDivisor(),

                              const SizedBox(height: 19),

                              // GOOGLE
                              _construirBotaoGoogle(),

                              const SizedBox(height: 27),

                              // CADASTRO
                              Center(child: _construirCadastro()),

                              const SizedBox(height: 12),
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
}

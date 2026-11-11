import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../dados/servicos/servico_autenticacao.dart';

class TelaCadastro extends StatefulWidget {
  const TelaCadastro({super.key, this.onCadastrar});

  final Future<void> Function({
    required String nome,
    required String email,
    required String senha,
  })?
  onCadastrar;

  @override
  State<TelaCadastro> createState() => _TelaCadastroState();
}

class _TelaCadastroState extends State<TelaCadastro> {
  // IDENTIDADE VISUAL

  static const Color _verde = Color(0xFF087443);
  static const Color _verdeEscuro = Color(0xFF064D31);
  static const Color _verdeClaro = Color(0xFFE5F1E8);
  static const Color _fundo = Color(0xFFF7FAF7);
  static const Color _textoSecundario = Color(0xFF718076);

  static const String _imagemLogo = 'assets/images/logo_hortasmart.png';

  // FORMULÁRIO E SERVIÇOS

  final _formulario = GlobalKey<FormState>();
  final _servicoAutenticacao = ServicoAutenticacao();

  final _nomeController = TextEditingController();
  final _emailController = TextEditingController();
  final _senhaController = TextEditingController();
  final _confirmarSenhaController = TextEditingController();

  // ESTADOS

  bool _mostrarSenha = false;
  bool _mostrarConfirmacao = false;
  bool _carregando = false;

  @override
  void dispose() {
    _nomeController.dispose();
    _emailController.dispose();
    _senhaController.dispose();
    _confirmarSenhaController.dispose();
    super.dispose();
  }

  // MENSAGENS DE ERRO

  String _mensagemErro(Object erro) {
    if (erro is FirebaseAuthException) {
      switch (erro.code) {
        case 'email-already-in-use':
          return 'Este e-mail já possui uma conta cadastrada.';

        case 'invalid-email':
          return 'O endereço de e-mail informado é inválido.';

        case 'weak-password':
          return 'A senha é muito fraca. Escolha outra senha.';

        case 'operation-not-allowed':
          return 'O cadastro por e-mail está desativado no Firebase.';

        case 'network-request-failed':
          return 'Sem conexão com a internet. Verifique sua rede.';

        case 'too-many-requests':
          return 'Muitas tentativas. Aguarde um pouco e tente novamente.';

        default:
          return 'Não foi possível criar sua conta. Tente novamente.';
      }
    }

    return 'Ocorreu um erro ao criar sua conta. Tente novamente.';
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

  // CADASTRO

  Future<void> _cadastrar() async {
    if (_carregando) return;

    if (_formulario.currentState?.validate() != true) {
      return;
    }

    setState(() {
      _carregando = true;
    });

    try {
      if (widget.onCadastrar != null) {
        await widget.onCadastrar!(
          nome: _nomeController.text.trim(),
          email: _emailController.text.trim(),
          senha: _senhaController.text,
        );
      } else {
        await _servicoAutenticacao.cadastrar(
          nome: _nomeController.text.trim(),
          email: _emailController.text.trim(),
          senha: _senhaController.text,
        );
      }

      if (!mounted) return;

      // MOSTRA A CONFIRMAÇÃO ANTES DE VOLTAR AO LOGIN.

      await _mostrarConfirmacaoCadastro();

      if (!mounted) return;

      // RETORNA PARA A TELA DE LOGIN.

      Navigator.of(context).pop();
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

  // DIÁLOGO DE CONFIRMAÇÃO

  Future<void> _mostrarConfirmacaoCadastro() async {
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          contentPadding: const EdgeInsets.fromLTRB(24, 28, 24, 12),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 76,
                height: 76,
                decoration: const BoxDecoration(
                  color: _verdeClaro,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.mark_email_read_rounded,
                  color: _verde,
                  size: 42,
                ),
              ),

              const SizedBox(height: 20),

              const Text(
                'Conta criada!',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: _verdeEscuro,
                  fontSize: 23,
                  fontWeight: FontWeight.w800,
                ),
              ),

              const SizedBox(height: 12),

              const Text(
                'Enviamos um e-mail de confirmação para você. '
                'Acesse sua caixa de entrada e confirme seu endereço '
                'antes de entrar no HortaSmart.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: _textoSecundario,
                  fontSize: 14,
                  height: 1.6,
                ),
              ),
            ],
          ),
          actionsPadding: const EdgeInsets.fromLTRB(24, 8, 24, 22),
          actions: [
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: _verde,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                ),
                child: const Text(
                  'Entendi',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                ),
              ),
            ),
          ],
        );
      },
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

  // RÓTULOS DOS CAMPOS

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

  // CAMPO DE NOME

  Widget _construirCampoNome() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _construirRotulo('Nome completo'),

        TextFormField(
          controller: _nomeController,
          textCapitalization: TextCapitalization.words,
          textInputAction: TextInputAction.next,
          autofillHints: const [AutofillHints.name],
          enabled: !_carregando,
          decoration: _decoracaoCampo(
            dica: 'Digite seu nome completo',
            icone: Icons.person_outline_rounded,
          ),
          validator: (valor) {
            if (valor == null || valor.trim().isEmpty) {
              return 'Informe seu nome.';
            }

            if (valor.trim().length < 2) {
              return 'Informe um nome válido.';
            }

            return null;
          },
        ),
      ],
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
          enabled: !_carregando,
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
          textInputAction: TextInputAction.next,
          autofillHints: const [AutofillHints.newPassword],
          enabled: !_carregando,
          decoration: _decoracaoCampo(
            dica: 'Crie uma senha',
            icone: Icons.lock_outline_rounded,
            sufixo: IconButton(
              tooltip: _mostrarSenha ? 'Ocultar senha' : 'Mostrar senha',
              onPressed:
                  _carregando
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
              return 'Crie uma senha.';
            }

            if (valor.length < 6) {
              return 'A senha precisa ter pelo menos 6 caracteres.';
            }

            return null;
          },
        ),
      ],
    );
  }

  // CONFIRMAR SENHA

  Widget _construirCampoConfirmarSenha() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _construirRotulo('Confirmar senha'),

        TextFormField(
          controller: _confirmarSenhaController,
          obscureText: !_mostrarConfirmacao,
          textInputAction: TextInputAction.done,
          autofillHints: const [AutofillHints.newPassword],
          enabled: !_carregando,
          onFieldSubmitted: (_) => _cadastrar(),
          decoration: _decoracaoCampo(
            dica: 'Digite sua senha novamente',
            icone: Icons.lock_reset_outlined,
            sufixo: IconButton(
              tooltip: _mostrarConfirmacao ? 'Ocultar senha' : 'Mostrar senha',
              onPressed:
                  _carregando
                      ? null
                      : () {
                        setState(() {
                          _mostrarConfirmacao = !_mostrarConfirmacao;
                        });
                      },
              icon: Icon(
                _mostrarConfirmacao
                    ? Icons.visibility_off_outlined
                    : Icons.visibility_outlined,
                color: _verdeEscuro,
                size: 21,
              ),
            ),
          ),
          validator: (valor) {
            if (valor == null || valor.isEmpty) {
              return 'Confirme sua senha.';
            }

            if (valor != _senhaController.text) {
              return 'As senhas não coincidem.';
            }

            return null;
          },
        ),
      ],
    );
  }

  // BOTÃO DE CADASTRO

  Widget _construirBotaoCadastro() {
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
          onPressed: _carregando ? null : _cadastrar,
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
                    'Criar minha conta',
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

  // LINK PARA LOGIN

  Widget _construirLogin() {
    return Wrap(
      alignment: WrapAlignment.center,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        const Text(
          'Já tem uma conta? ',
          style: TextStyle(color: _textoSecundario, fontSize: 13),
        ),

        GestureDetector(
          onTap: _carregando ? null : () => Navigator.of(context).pop(),
          child: const Text(
            'Fazer login',
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

  // CABEÇALHO

  Widget _construirCabecalho() {
    return Column(
      children: [
        _construirLogo(),

        const SizedBox(height: 17),

        const Text(
          'Crie sua conta no',
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
          'Comece a cuidar dos seus canteiros com inteligência.',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 13, color: _textoSecundario, height: 1.5),
        ),
      ],
    );
  }

  // INTERFACE PRINCIPAL

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _fundo,
      body: Stack(
        children: [
          // FORMAS DECORATIVAS

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
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            // VOLTAR

                            Align(
                              alignment: Alignment.centerLeft,
                              child: IconButton(
                                tooltip: 'Voltar para o login',
                                onPressed:
                                    _carregando
                                        ? null
                                        : () => Navigator.of(context).pop(),
                                icon: const Icon(
                                  Icons.arrow_back_rounded,
                                  color: _verdeEscuro,
                                ),
                              ),
                            ),

                            const SizedBox(height: 5),

                            // CABEÇALHO
                            _construirCabecalho(),

                            const SizedBox(height: 31),

                            // NOME
                            _construirCampoNome(),

                            const SizedBox(height: 19),

                            // E-MAIL
                            _construirCampoEmail(),

                            const SizedBox(height: 19),

                            // SENHA
                            _construirCampoSenha(),

                            const SizedBox(height: 19),

                            // CONFIRMAÇÃO
                            _construirCampoConfirmarSenha(),

                            const SizedBox(height: 28),

                            // CRIAR CONTA
                            _construirBotaoCadastro(),

                            const SizedBox(height: 25),

                            // ACESSO EXISTENTE
                            Center(child: _construirLogin()),

                            const SizedBox(height: 16),
                          ],
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

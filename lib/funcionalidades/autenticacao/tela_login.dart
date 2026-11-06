import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../dados/servicos/servico_autenticacao.dart';
import 'tela_cadastro.dart';

class TelaLogin extends StatefulWidget {
  const TelaLogin({
    super.key,
    this.onEntrar,
  });

  final Future<void> Function(String email, String senha)? onEntrar;

  @override
  State<TelaLogin> createState() => _TelaLoginState();
}

class _TelaLoginState extends State<TelaLogin> {
  static const Color _verde = Color(0xFF087443);
  static const Color _verdeEscuro = Color(0xFF064D31);

  final _formulario = GlobalKey<FormState>();
  final _servicoAutenticacao = ServicoAutenticacao();

  final _emailController = TextEditingController();
  final _senhaController = TextEditingController();

  bool _mostrarSenha = false;
  bool _carregando = false;
  bool _recuperandoSenha = false;

  @override
  void dispose() {
    _emailController.dispose();
    _senhaController.dispose();
    super.dispose();
  }

  String _mensagemErro(Object erro) {
    if (erro is FirebaseAuthException) {
      switch (erro.code) {
        case 'email-nao-verificado':
          return 'Confirme seu e-mail antes de entrar. '
              'Enviamos uma nova mensagem de confirmação.';

        case 'invalid-email':
          return 'O endereço de e-mail informado é inválido.';

        case 'user-disabled':
          return 'Esta conta está desativada.';

        case 'user-not-found':
        case 'wrong-password':
        case 'invalid-credential':
          return 'E-mail ou senha incorretos.';

        case 'too-many-requests':
          return 'Muitas tentativas. Aguarde um pouco e tente novamente.';

        case 'network-request-failed':
          return 'Sem conexão com a internet. Verifique sua rede.';

        case 'operation-not-allowed':
          return 'O login por e-mail está desativado no Firebase.';

        default:
          return 'Não foi possível entrar. Tente novamente.';
      }
    }

    return 'Ocorreu um erro ao entrar. Tente novamente.';
  }

  Future<void> _entrar() async {
    if (!_formulario.currentState!.validate()) {
      return;
    }

    setState(() {
      _carregando = true;
    });

    try {
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

      // Fecha a tela de login e retorna à tela inicial.
      // O StreamBuilder do aplicativo identificará o usuário
      // autenticado e exibirá a TelaPrincipal.
      Navigator.of(context).popUntil(
        (rota) => rota.isFirst,
      );
    } catch (erro) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_mensagemErro(erro)),
          backgroundColor: Colors.red.shade700,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _carregando = false;
        });
      }
    }
  }

  Future<void> _recuperarSenha() async {
    final emailInicial = _emailController.text.trim();

    final controladorEmail = TextEditingController(
      text: emailInicial,
    );

    final email = await showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Recuperar senha'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Informe o e-mail cadastrado para receber '
                'as instruções de redefinição da senha.',
              ),
              const SizedBox(height: 16),
              TextField(
                controller: controladorEmail,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                  labelText: 'Seu e-mail',
                  prefixIcon: Icon(Icons.email_outlined),
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: _verde,
                foregroundColor: Colors.white,
              ),
              onPressed: () {
                final valor = controladorEmail.text.trim();

                if (valor.isEmpty ||
                    !valor.contains('@') ||
                    !valor.contains('.')) {
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

    if (email == null || !mounted) {
      return;
    }

    setState(() {
      _recuperandoSenha = true;
    });

    try {
      await _servicoAutenticacao.recuperarSenha(email);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Se o endereço estiver cadastrado, '
            'você receberá um e-mail para redefinir a senha.',
          ),
          backgroundColor: _verde,
        ),
      );
    } catch (erro) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_mensagemErro(erro)),
          backgroundColor: Colors.red.shade700,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _recuperandoSenha = false;
        });
      }
    }
  }

  void _abrirCadastro() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const TelaCadastro(),
      ),
    );
  }

  InputDecoration _decoracaoCampo({
    required String titulo,
    required IconData icone,
    Widget? sufixo,
  }) {
    return InputDecoration(
      labelText: titulo,
      prefixIcon: Icon(icone, color: _verde),
      suffixIcon: sufixo,
      filled: true,
      fillColor: const Color(0xFFF7F9F7),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(
          color: Color(0xFFE2EAE3),
        ),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(
          color: Color(0xFFE2EAE3),
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(
          color: _verde,
          width: 1.5,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F8F5),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF5F8F5),
        elevation: 0,
        foregroundColor: _verdeEscuro,
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: Form(
                key: _formulario,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 70,
                        height: 70,
                        decoration: BoxDecoration(
                          color: const Color(0xFFE1F1E7),
                          borderRadius: BorderRadius.circular(22),
                        ),
                        child: const Icon(
                          Icons.eco_rounded,
                          color: _verde,
                          size: 42,
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    const Center(
                      child: Text(
                        'Bem-vindo de volta!',
                        style: TextStyle(
                          fontSize: 27,
                          fontWeight: FontWeight.w800,
                          color: _verdeEscuro,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Center(
                      child: Text(
                        'Entre para acessar seu HortaSmart.',
                        style: TextStyle(
                          color: Color(0xFF718076),
                          fontSize: 14,
                        ),
                      ),
                    ),
                    const SizedBox(height: 36),
                    const Text(
                      'E-mail',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: _verdeEscuro,
                      ),
                    ),
                    const SizedBox(height: 9),
                    TextFormField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      textInputAction: TextInputAction.next,
                      decoration: _decoracaoCampo(
                        titulo: 'seuemail@exemplo.com',
                        icone: Icons.email_outlined,
                      ),
                      validator: (valor) {
                        if (valor == null || valor.trim().isEmpty) {
                          return 'Informe seu e-mail.';
                        }

                        if (!valor.contains('@') || !valor.contains('.')) {
                          return 'Informe um e-mail válido.';
                        }

                        return null;
                      },
                    ),
                    const SizedBox(height: 22),
                    const Text(
                      'Senha',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: _verdeEscuro,
                      ),
                    ),
                    const SizedBox(height: 9),
                    TextFormField(
                      controller: _senhaController,
                      obscureText: !_mostrarSenha,
                      textInputAction: TextInputAction.done,
                      onFieldSubmitted: (_) => _entrar(),
                      decoration: _decoracaoCampo(
                        titulo: 'Digite sua senha',
                        icone: Icons.lock_outline,
                        sufixo: IconButton(
                          onPressed: () {
                            setState(() {
                              _mostrarSenha = !_mostrarSenha;
                            });
                          },
                          icon: Icon(
                            _mostrarSenha
                                ? Icons.visibility_off_outlined
                                : Icons.visibility_outlined,
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
                    const SizedBox(height: 12),
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: _recuperandoSenha || _carregando
                            ? null
                            : _recuperarSenha,
                        child: _recuperandoSenha
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: _verde,
                                ),
                              )
                            : const Text(
                                'Esqueceu sua senha?',
                                style: TextStyle(
                                  color: _verde,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                      ),
                    ),
                    const SizedBox(height: 18),
                    SizedBox(
                      width: double.infinity,
                      height: 54,
                      child: ElevatedButton(
                        onPressed: _carregando ? null : _entrar,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _verde,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: _carregando
                            ? const SizedBox(
                                width: 23,
                                height: 23,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              )
                            : const Text(
                                'Entrar',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                      ),
                    ),
                    const SizedBox(height: 26),
                    Center(
                      child: Wrap(
                        alignment: WrapAlignment.center,
                        children: [
                          const Text(
                            'Ainda não tem uma conta? ',
                            style: TextStyle(
                              color: Color(0xFF718076),
                            ),
                          ),
                          GestureDetector(
                            onTap: _abrirCadastro,
                            child: const Text(
                              'Cadastre-se',
                              style: TextStyle(
                                color: _verde,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

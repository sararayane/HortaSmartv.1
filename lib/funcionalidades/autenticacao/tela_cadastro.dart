import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../dados/servicos/servico_autenticacao.dart';

class TelaCadastro extends StatefulWidget {
  const TelaCadastro({
    super.key,
    this.onCadastrar,
  });

  final Future<void> Function({
    required String nome,
    required String email,
    required String senha,
  })? onCadastrar;

  @override
  State<TelaCadastro> createState() => _TelaCadastroState();
}

class _TelaCadastroState extends State<TelaCadastro> {
  static const Color _verde = Color(0xFF087443);
  static const Color _verdeEscuro = Color(0xFF064D31);

  final _formulario = GlobalKey<FormState>();

  final _servicoAutenticacao = ServicoAutenticacao();

  final _nomeController = TextEditingController();
  final _emailController = TextEditingController();
  final _senhaController = TextEditingController();
  final _confirmarSenhaController = TextEditingController();

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

  Future<void> _cadastrar() async {
    if (!_formulario.currentState!.validate()) {
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

      // Retorna para a tela inicial após o cadastro.
      Navigator.of(context).popUntil((rota) => rota.isFirst);

      if (!mounted) return;

      await showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (context) {
          return AlertDialog(
            icon: const Icon(
              Icons.mark_email_read_outlined,
              color: _verde,
              size: 48,
            ),
            title: const Text(
              'Conta criada!',
              textAlign: TextAlign.center,
            ),
            content: const Text(
              'Enviamos um e-mail de confirmação para você. '
              'Acesse sua caixa de entrada e confirme seu endereço '
              'antes de entrar no HortaSmart.',
              textAlign: TextAlign.center,
            ),
            actions: [
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _verde,
                    foregroundColor: Colors.white,
                  ),
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: const Text('Entendi'),
                ),
              ),
            ],
          );
        },
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
                          Icons.person_add_alt_1_rounded,
                          color: _verde,
                          size: 38,
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    const Center(
                      child: Text(
                        'Crie sua conta',
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
                        'Comece a gerenciar sua plantação com inteligência.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Color(0xFF718076),
                          fontSize: 14,
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),
                    const Text(
                      'Nome completo',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: _verdeEscuro,
                      ),
                    ),
                    const SizedBox(height: 9),
                    TextFormField(
                      controller: _nomeController,
                      textCapitalization: TextCapitalization.words,
                      textInputAction: TextInputAction.next,
                      decoration: _decoracaoCampo(
                        titulo: 'Digite seu nome',
                        icone: Icons.person_outline,
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
                    const SizedBox(height: 20),
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
                    const SizedBox(height: 20),
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
                      textInputAction: TextInputAction.next,
                      decoration: _decoracaoCampo(
                        titulo: 'Crie uma senha',
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
                          return 'Crie uma senha.';
                        }

                        if (valor.length < 6) {
                          return 'A senha precisa ter pelo menos 6 caracteres.';
                        }

                        return null;
                      },
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      'Confirmar senha',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: _verdeEscuro,
                      ),
                    ),
                    const SizedBox(height: 9),
                    TextFormField(
                      controller: _confirmarSenhaController,
                      obscureText: !_mostrarConfirmacao,
                      textInputAction: TextInputAction.done,
                      onFieldSubmitted: (_) => _cadastrar(),
                      decoration: _decoracaoCampo(
                        titulo: 'Digite a senha novamente',
                        icone: Icons.lock_reset_outlined,
                        sufixo: IconButton(
                          onPressed: () {
                            setState(() {
                              _mostrarConfirmacao = !_mostrarConfirmacao;
                            });
                          },
                          icon: Icon(
                            _mostrarConfirmacao
                                ? Icons.visibility_off_outlined
                                : Icons.visibility_outlined,
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
                    const SizedBox(height: 28),
                    SizedBox(
                      width: double.infinity,
                      height: 54,
                      child: ElevatedButton(
                        onPressed: _carregando ? null : _cadastrar,
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
                                'Criar minha conta',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    Center(
                      child: Wrap(
                        alignment: WrapAlignment.center,
                        children: [
                          const Text(
                            'Já tem uma conta? ',
                            style: TextStyle(
                              color: Color(0xFF718076),
                            ),
                          ),
                          GestureDetector(
                            onTap: () => Navigator.pop(context),
                            child: const Text(
                              'Fazer login',
                              style: TextStyle(
                                color: _verde,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
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

import 'dart:convert';
import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../compartilhado/constantes/cores.dart';

class CartaoPerfil extends StatefulWidget {
  const CartaoPerfil({super.key});

  @override
  State<CartaoPerfil> createState() => _CartaoPerfilState();
}

class _CartaoPerfilState extends State<CartaoPerfil> {
  final FirebaseAuth _autenticacao = FirebaseAuth.instance;
  final FirebaseFirestore _banco = FirebaseFirestore.instance;
  final ImagePicker _seletorImagem = ImagePicker();

  bool _salvando = false;
  Uint8List? _fotoPerfil;

  User? get _usuario => _autenticacao.currentUser;

  @override
  void initState() {
    super.initState();
    _carregarFoto();
  }

  Future<void> _carregarFoto() async {
    final usuario = _usuario;
    if (usuario == null) return;

    try {
      final preferencias = await SharedPreferences.getInstance();
      final imagemSalva = preferencias.getString(
        'foto_perfil_${usuario.uid}',
      );

      if (imagemSalva != null && mounted) {
        setState(() {
          _fotoPerfil = base64Decode(imagemSalva);
        });
      }
    } catch (_) {
      // O aplicativo continua funcionando sem foto.
    }
  }

  void _mostrarMensagem(String mensagem) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(mensagem),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<String?> _solicitarSenha({
    String titulo = 'Confirmar identidade',
  }) async {
    final controlador = TextEditingController();

    final senha = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(titulo),
        content: TextField(
          controller: controlador,
          obscureText: true,
          autofocus: true,
          decoration: const InputDecoration(
            labelText: 'Senha atual',
            prefixIcon: Icon(Icons.lock_outline),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(dialogContext, controlador.text);
            },
            child: const Text('Confirmar'),
          ),
        ],
      ),
    );

    controlador.dispose();
    return senha;
  }

  // EDITAR NOME

  Future<void> _editarNome() async {
    final usuario = _usuario;
    if (usuario == null) return;

    final controlador = TextEditingController(
      text: usuario.displayName ?? '',
    );

    final nome = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Editar nome'),
        content: TextField(
          controller: controlador,
          autofocus: true,
          maxLength: 60,
          decoration: const InputDecoration(
            labelText: 'Nome completo',
            hintText: 'Digite seu nome',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(
                dialogContext,
                controlador.text.trim(),
              );
            },
            child: const Text('Salvar'),
          ),
        ],
      ),
    );

    controlador.dispose();

    if (nome == null || nome.isEmpty || !mounted) return;

    setState(() => _salvando = true);

    try {
      await usuario.updateDisplayName(nome);

      await _banco.collection('usuarios').doc(usuario.uid).set({
        'nome': nome,
        'email': usuario.email ?? '',
        'ultimoAcesso': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      await usuario.reload();

      if (!mounted) return;

      setState(() => _salvando = false);
      _mostrarMensagem('Nome atualizado com sucesso!');
    } catch (_) {
      if (!mounted) return;

      setState(() => _salvando = false);
      _mostrarMensagem('Não foi possível atualizar o nome.');
    }
  }

  // ALTERAR SENHA

  Future<void> _alterarSenha() async {
    final usuario = _usuario;
    if (usuario == null || usuario.email == null) return;

    final controladorAtual = TextEditingController();
    final controladorNova = TextEditingController();
    final controladorConfirmacao = TextEditingController();

    final senhas = await showDialog<List<String>>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Alterar senha'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: controladorAtual,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Senha atual',
                  prefixIcon: Icon(Icons.lock_outline),
                ),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: controladorNova,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Nova senha',
                  prefixIcon: Icon(Icons.lock_reset),
                  helperText: 'Mínimo de 6 caracteres',
                ),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: controladorConfirmacao,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Confirmar nova senha',
                  prefixIcon: Icon(Icons.lock_outline),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(
                dialogContext,
                [
                  controladorAtual.text,
                  controladorNova.text,
                  controladorConfirmacao.text,
                ],
              );
            },
            child: const Text('Continuar'),
          ),
        ],
      ),
    );

    controladorAtual.dispose();
    controladorNova.dispose();
    controladorConfirmacao.dispose();

    if (senhas == null || !mounted) return;

    final senhaAtual = senhas[0];
    final novaSenha = senhas[1];
    final confirmacao = senhas[2];

    if (senhaAtual.isEmpty || novaSenha.isEmpty || confirmacao.isEmpty) {
      _mostrarMensagem('Preencha todos os campos.');
      return;
    }

    if (novaSenha.length < 6) {
      _mostrarMensagem(
        'A nova senha precisa ter pelo menos 6 caracteres.',
      );
      return;
    }

    if (novaSenha != confirmacao) {
      _mostrarMensagem('As novas senhas não coincidem.');
      return;
    }

    if (senhaAtual == novaSenha) {
      _mostrarMensagem(
        'A nova senha precisa ser diferente da atual.',
      );
      return;
    }

    setState(() => _salvando = true);

    try {
      final credencial = EmailAuthProvider.credential(
        email: usuario.email!,
        password: senhaAtual,
      );

      await usuario.reauthenticateWithCredential(credencial);
      await usuario.updatePassword(novaSenha);

      if (!mounted) return;

      setState(() => _salvando = false);
      _mostrarMensagem('Senha alterada com sucesso!');
    } on FirebaseAuthException catch (erro) {
      if (!mounted) return;

      setState(() => _salvando = false);

      if (erro.code == 'wrong-password' || erro.code == 'invalid-credential') {
        _mostrarMensagem('A senha atual está incorreta.');
      } else if (erro.code == 'weak-password') {
        _mostrarMensagem('A nova senha é muito fraca.');
      } else {
        _mostrarMensagem('Não foi possível alterar a senha.');
      }
    } catch (_) {
      if (!mounted) return;

      setState(() => _salvando = false);
      _mostrarMensagem('Ocorreu um erro ao alterar a senha.');
    }
  }

  // ALTERAR E-MAIL

  Future<void> _alterarEmail() async {
    final usuario = _usuario;
    if (usuario == null || usuario.email == null) return;

    final controladorEmail = TextEditingController(
      text: usuario.email,
    );

    final novoEmail = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Alterar e-mail'),
        content: TextField(
          controller: controladorEmail,
          keyboardType: TextInputType.emailAddress,
          decoration: const InputDecoration(
            labelText: 'Novo e-mail',
            prefixIcon: Icon(Icons.email_outlined),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(
                dialogContext,
                controladorEmail.text.trim(),
              );
            },
            child: const Text('Continuar'),
          ),
        ],
      ),
    );

    controladorEmail.dispose();

    if (novoEmail == null || !mounted) return;

    final email = novoEmail.trim();

    if (email.isEmpty || !email.contains('@')) {
      _mostrarMensagem('Digite um e-mail válido.');
      return;
    }

    if (email.toLowerCase() == usuario.email!.toLowerCase()) {
      _mostrarMensagem('Digite um e-mail diferente do atual.');
      return;
    }

    final senha = await _solicitarSenha();
    if (senha == null || senha.isEmpty || !mounted) return;

    setState(() => _salvando = true);

    try {
      final credencial = EmailAuthProvider.credential(
        email: usuario.email!,
        password: senha,
      );

      await usuario.reauthenticateWithCredential(credencial);
      await usuario.verifyBeforeUpdateEmail(email);

      if (!mounted) return;

      setState(() => _salvando = false);

      _mostrarMensagem(
        'Enviamos um link de verificação para $email. '
        'Confirme o endereço para concluir a alteração.',
      );
    } on FirebaseAuthException catch (erro) {
      if (!mounted) return;

      setState(() => _salvando = false);

      if (erro.code == 'wrong-password' || erro.code == 'invalid-credential') {
        _mostrarMensagem('A senha informada está incorreta.');
      } else if (erro.code == 'email-already-in-use') {
        _mostrarMensagem('Esse e-mail já está cadastrado.');
      } else if (erro.code == 'invalid-email') {
        _mostrarMensagem('O endereço de e-mail é inválido.');
      } else {
        _mostrarMensagem('Não foi possível iniciar a alteração.');
      }
    } catch (_) {
      if (!mounted) return;

      setState(() => _salvando = false);
      _mostrarMensagem('Ocorreu um erro ao alterar o e-mail.');
    }
  }

  // FOTO DE PERFIL

  Future<ImageSource?> _escolherOrigemFoto() async {
    return showModalBottomSheet<ImageSource>(
      context: context,
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Alterar foto de perfil',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 20),
                ListTile(
                  leading: const Icon(Icons.camera_alt),
                  title: const Text('Tirar uma foto'),
                  onTap: () {
                    Navigator.pop(context, ImageSource.camera);
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.photo_library),
                  title: const Text('Escolher da galeria'),
                  onTap: () {
                    Navigator.pop(context, ImageSource.gallery);
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _alterarFoto() async {
    final usuario = _usuario;
    if (usuario == null) return;

    try {
      final origem = await _escolherOrigemFoto();

      if (origem == null || !mounted) return;

      final imagem = await _seletorImagem.pickImage(
        source: origem,
        imageQuality: 65,
        maxWidth: 400,
        maxHeight: 400,
      );

      if (imagem == null || !mounted) return;

      setState(() => _salvando = true);

      final bytes = await imagem.readAsBytes();
      final imagemCodificada = base64Encode(bytes);

      final preferencias = await SharedPreferences.getInstance();

      await preferencias.setString(
        'foto_perfil_${usuario.uid}',
        imagemCodificada,
      );

      if (!mounted) return;

      setState(() {
        _fotoPerfil = bytes;
        _salvando = false;
      });

      _mostrarMensagem('Foto de perfil atualizada!');
    } catch (_) {
      if (!mounted) return;

      setState(() => _salvando = false);
      _mostrarMensagem('Não foi possível salvar a foto.');
    }
  }

  // EXCLUIR CONTA

  Future<bool> _confirmarExclusao() async {
    final resultado = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Excluir conta?'),
        content: const Text(
          'Essa ação é permanente. Sua conta e os dados '
          'dos seus canteiros no HortaSmart serão excluídos. '
          'Não será possível recuperar essas informações.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Excluir minha conta'),
          ),
        ],
      ),
    );

    return resultado ?? false;
  }

  Future<void> _excluirConta() async {
    final usuario = _usuario;
    if (usuario == null) return;

    final confirmou = await _confirmarExclusao();
    if (!confirmou || !mounted) return;

    final senha = await _solicitarSenha(
      titulo: 'Confirme sua senha para excluir a conta',
    );

    if (senha == null || senha.isEmpty || !mounted) return;

    setState(() => _salvando = true);

    try {
      final credencial = EmailAuthProvider.credential(
        email: usuario.email!,
        password: senha,
      );

      await usuario.reauthenticateWithCredential(credencial);

      final referenciaUsuario = _banco.collection('usuarios').doc(usuario.uid);

      final referenciaCanteiros = referenciaUsuario.collection('canteiros');

      final documentos = await referenciaCanteiros.get();

      for (var inicio = 0; inicio < documentos.docs.length; inicio += 450) {
        final lote = _banco.batch();

        final fim = (inicio + 450 < documentos.docs.length)
            ? inicio + 450
            : documentos.docs.length;

        for (var i = inicio; i < fim; i++) {
          lote.delete(documentos.docs[i].reference);
        }

        await lote.commit();
      }

      await referenciaUsuario.delete();
      await usuario.delete();

      final preferencias = await SharedPreferences.getInstance();

      await preferencias.remove(
        'foto_perfil_${usuario.uid}',
      );

      if (!mounted) return;

      setState(() => _salvando = false);

      _mostrarMensagem(
        'Conta excluída. Você precisará entrar novamente.',
      );
    } on FirebaseAuthException catch (erro) {
      if (!mounted) return;

      setState(() => _salvando = false);

      if (erro.code == 'wrong-password' || erro.code == 'invalid-credential') {
        _mostrarMensagem('A senha informada está incorreta.');
      } else if (erro.code == 'requires-recent-login') {
        _mostrarMensagem(
          'Faça login novamente antes de excluir sua conta.',
        );
      } else {
        _mostrarMensagem('Não foi possível excluir a conta.');
      }
    } catch (_) {
      if (!mounted) return;

      setState(() => _salvando = false);

      _mostrarMensagem(
        'Ocorreu um erro ao excluir a conta. '
        'Verifique os dados no Firebase antes de tentar novamente.',
      );
    }
  }

  // INTERFACE

  @override
  Widget build(BuildContext context) {
    final usuario = _usuario;

    if (usuario == null) {
      return const SizedBox.shrink();
    }

    final nome = usuario.displayName?.isNotEmpty == true
        ? usuario.displayName!
        : 'Usuário HortaSmart';

    final email = usuario.email ?? 'E-mail não disponível';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(17),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: const Color(0xFFE5ECE6),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Stack(
                clipBehavior: Clip.none,
                children: [
                  CircleAvatar(
                    radius: 25,
                    backgroundColor: CoresHortasmart.verdeClaro,
                    backgroundImage:
                        _fotoPerfil != null ? MemoryImage(_fotoPerfil!) : null,
                    child: _fotoPerfil == null
                        ? const Icon(
                            Icons.person_rounded,
                            color: CoresHortasmart.verde,
                            size: 28,
                          )
                        : null,
                  ),
                  Positioned(
                    right: -3,
                    bottom: -3,
                    child: Material(
                      color: CoresHortasmart.verde,
                      shape: const CircleBorder(),
                      child: InkWell(
                        onTap: _salvando ? null : _alterarFoto,
                        customBorder: const CircleBorder(),
                        child: const Padding(
                          padding: EdgeInsets.all(6),
                          child: Icon(
                            Icons.camera_alt_rounded,
                            size: 13,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'Minha conta',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w900,
                    color: CoresHortasmart.texto,
                  ),
                ),
              ),
              IconButton(
                onPressed: _salvando ? null : _editarNome,
                tooltip: 'Editar nome',
                icon: const Icon(
                  Icons.edit_rounded,
                  color: CoresHortasmart.verde,
                ),
              ),
            ],
          ),
          const Divider(height: 25),
          const Text(
            'Nome',
            style: TextStyle(
              fontSize: 11,
              color: CoresHortasmart.textoSecundario,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            nome,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w800,
              color: CoresHortasmart.texto,
            ),
          ),
          const SizedBox(height: 15),
          const Text(
            'E-mail',
            style: TextStyle(
              fontSize: 11,
              color: CoresHortasmart.textoSecundario,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            email,
            style: const TextStyle(
              fontSize: 13,
              color: CoresHortasmart.texto,
            ),
          ),
          const Divider(height: 30),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: _salvando ? null : _alterarEmail,
              icon: const Icon(Icons.email_outlined),
              label: const Text('Alterar e-mail'),
              style: OutlinedButton.styleFrom(
                foregroundColor: CoresHortasmart.verde,
                padding: const EdgeInsets.symmetric(vertical: 13),
                side: const BorderSide(
                  color: CoresHortasmart.verde,
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: _salvando ? null : _alterarSenha,
              icon: const Icon(Icons.lock_reset_rounded),
              label: const Text('Alterar senha'),
              style: OutlinedButton.styleFrom(
                foregroundColor: CoresHortasmart.verde,
                padding: const EdgeInsets.symmetric(vertical: 13),
                side: const BorderSide(
                  color: CoresHortasmart.verde,
                ),
              ),
            ),
          ),
          const Divider(height: 30),
          SizedBox(
            width: double.infinity,
            child: TextButton.icon(
              onPressed: _salvando ? null : _excluirConta,
              icon: const Icon(
                Icons.delete_forever_outlined,
                color: Colors.red,
              ),
              label: const Text(
                'Excluir minha conta',
                style: TextStyle(color: Colors.red),
              ),
            ),
          ),
          if (_salvando) ...[
            const SizedBox(height: 15),
            const LinearProgressIndicator(),
          ],
        ],
      ),
    );
  }
}

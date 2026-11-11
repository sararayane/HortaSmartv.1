import 'dart:async';
import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../compartilhado/componentes/cabecalho_aplicativo.dart';
import '../compartilhado/constantes/cores.dart';
import '../dados/modelos/canteiro.dart';
import '../dados/repositorios/repositorio_canteiro.dart';
import '../funcionalidades/configuracoes/tela_configuracoes.dart';
import '../funcionalidades/historico/tela_historico.dart';
import '../funcionalidades/irrigacao/tela_irrigacao.dart';
import '../funcionalidades/painel/tela_painel.dart';
import 'rotas.dart';

class TelaPrincipal extends StatefulWidget {
  const TelaPrincipal({super.key});

  @override
  State<TelaPrincipal> createState() => _TelaPrincipalState();
}

class _TelaPrincipalState extends State<TelaPrincipal> {
  static const String _chaveFotos = 'hortasmart_fotos_canteiros';

  int _indiceSelecionado = RotasHortasmart.painel;
  String? _canteiroInicialIrrigacao;

  List<Canteiro> _canteiros = [];

  final RepositorioCanteiro _repositorio = RepositorioCanteiro();
  final ImagePicker _seletorImagem = ImagePicker();

  StreamSubscription<List<Canteiro>>? _assinaturaCanteiros;

  Map<String, String> _fotosSalvas = {};

  bool _carregando = true;

  @override
  void initState() {
    super.initState();
    _inicializarCanteiros();
  }

  @override
  void dispose() {
    _assinaturaCanteiros?.cancel();
    super.dispose();
  }

  /// Carrega os canteiros do usuário e acompanha alterações no Firestore.
  Future<void> _inicializarCanteiros() async {
    try {
      _fotosSalvas = await _lerMapaFotos();

      // Não cria dados de demonstração.
      // Os canteiros são carregados diretamente do Firestore.
      _assinaturaCanteiros = _repositorio.acompanharCanteiros().listen(
        (lista) {
          final canteirosComFotos =
              lista.map((canteiro) {
                final imagem = _fotosSalvas[canteiro.id];

                if (imagem == null || imagem.isEmpty) {
                  return canteiro;
                }

                return canteiro.copiarCom(imagemBase64: imagem);
              }).toList();

          if (!mounted) return;

          setState(() {
            _canteiros = canteirosComFotos;
            _carregando = false;
          });
        },
        onError: (Object erro) {
          debugPrint('Erro ao acompanhar canteiros: $erro');

          if (!mounted) return;

          setState(() {
            _carregando = false;
          });

          _mostrarMensagem(
            'Não foi possível carregar os canteiros do Firebase.',
          );
        },
      );
    } catch (erro) {
      debugPrint('Erro ao inicializar canteiros: $erro');

      if (!mounted) return;

      setState(() {
        _carregando = false;
      });

      _mostrarMensagem(
        'Erro ao conectar aos canteiros. Verifique sua conexão e as regras do Firestore.',
      );
    }
  }

  /// Lê o mapa de imagens salvo localmente.
  Future<Map<String, String>> _lerMapaFotos() async {
    final preferencias = await SharedPreferences.getInstance();

    final conteudo = preferencias.getString(_chaveFotos);

    if (conteudo == null || conteudo.isEmpty) {
      return {};
    }

    try {
      final decodificado = jsonDecode(conteudo);
      return Map<String, String>.from(decodificado);
    } catch (erro) {
      debugPrint('Erro ao ler fotos salvas: $erro');
      return {};
    }
  }

  /// Salva o mapa de imagens no armazenamento local.
  Future<void> _salvarMapaFotos(Map<String, String> fotos) async {
    final preferencias = await SharedPreferences.getInstance();

    await preferencias.setString(_chaveFotos, jsonEncode(fotos));
  }

  void _mostrarMensagem(String mensagem) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(mensagem), behavior: SnackBarBehavior.floating),
    );
  }

  /// Atualiza um canteiro e salva a alteração no Firestore.
  void _atualizarCanteiro(Canteiro atualizado) {
    _salvarCanteiroNaNuvem(atualizado);
  }

  Future<void> _salvarCanteiroNaNuvem(Canteiro canteiro) async {
    try {
      await _repositorio.atualizar(canteiro);

      if (!mounted) return;

      _mostrarMensagem('Canteiro atualizado com sucesso.');
    } catch (erro) {
      debugPrint('Erro ao atualizar canteiro: $erro');

      _mostrarMensagem('Não foi possível salvar as alterações na nuvem.');
    }
  }

  /// Seleciona uma imagem e salva em Base64 no armazenamento local.
  Future<void> _selecionarFoto(Canteiro canteiro, ImageSource origem) async {
    try {
      final XFile? imagem = await _seletorImagem.pickImage(
        source: origem,
        imageQuality: 65,
        maxWidth: 1000,
      );

      if (imagem == null || !mounted) return;

      final bytes = await imagem.readAsBytes();
      final imagemBase64 = base64Encode(bytes);

      _fotosSalvas[canteiro.id] = imagemBase64;

      await _salvarMapaFotos(_fotosSalvas);

      if (!mounted) return;

      setState(() {
        _canteiros =
            _canteiros.map((item) {
              if (item.id == canteiro.id) {
                return item.copiarCom(imagemBase64: imagemBase64);
              }

              return item;
            }).toList();
      });

      _mostrarMensagem('Foto do canteiro atualizada!');
    } catch (erro) {
      debugPrint('Erro ao selecionar imagem: $erro');

      _mostrarMensagem('Não foi possível selecionar a imagem.');
    }
  }

  /// Remove a imagem do canteiro.
  Future<void> _removerFoto(Canteiro canteiro) async {
    try {
      _fotosSalvas.remove(canteiro.id);

      await _salvarMapaFotos(_fotosSalvas);

      if (!mounted) return;

      setState(() {
        _canteiros =
            _canteiros.map((item) {
              if (item.id == canteiro.id) {
                return item.copiarCom(removerImagem: true);
              }

              return item;
            }).toList();
      });

      _mostrarMensagem('Foto removida com sucesso.');
    } catch (erro) {
      debugPrint('Erro ao remover imagem: $erro');

      _mostrarMensagem('Não foi possível remover a foto.');
    }
  }

  Future<void> _abrirOpcoesFoto(Canteiro canteiro) async {
    await showModalBottomSheet<void>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Foto de ${canteiro.nome}',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                ListTile(
                  leading: const Icon(Icons.camera_alt_outlined),
                  title: const Text('Tirar foto'),
                  onTap: () {
                    Navigator.pop(context);
                    _selecionarFoto(canteiro, ImageSource.camera);
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.photo_library_outlined),
                  title: const Text('Escolher da galeria'),
                  onTap: () {
                    Navigator.pop(context);
                    _selecionarFoto(canteiro, ImageSource.gallery);
                  },
                ),
                if (canteiro.imagemBase64 != null &&
                    canteiro.imagemBase64!.isNotEmpty)
                  ListTile(
                    leading: const Icon(
                      Icons.delete_outline,
                      color: Colors.red,
                    ),
                    title: const Text('Remover foto'),
                    onTap: () {
                      Navigator.pop(context);
                      _removerFoto(canteiro);
                    },
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  /// Cadastra um novo canteiro no Firestore.
  void _adicionarCanteiro(Canteiro novo) {
    _salvarNovoCanteiro(novo);
  }

  Future<void> _salvarNovoCanteiro(Canteiro novo) async {
    try {
      await _repositorio.salvar(novo);

      if (!mounted) return;

      _mostrarMensagem('Canteiro cadastrado com sucesso!');
    } catch (erro) {
      debugPrint('Erro ao adicionar canteiro: $erro');

      _mostrarMensagem('Não foi possível cadastrar o canteiro na nuvem.');
    }
  }

  /// Remove um canteiro do Firestore.
  void _removerCanteiro(String id) {
    _excluirCanteiroNaNuvem(id);
  }

  Future<void> _excluirCanteiroNaNuvem(String id) async {
    try {
      await _repositorio.excluir(id);

      _fotosSalvas.remove(id);
      await _salvarMapaFotos(_fotosSalvas);

      if (!mounted) return;

      _mostrarMensagem('Canteiro removido com sucesso.');
    } catch (erro) {
      debugPrint('Erro ao excluir canteiro: $erro');

      _mostrarMensagem('Não foi possível excluir o canteiro da nuvem.');
    }
  }

  /// Abre a central de notificações.
  /// A integração com alertas reais será feita quando os eventos do sistema
  /// estiverem definidos.
  void _abrirNotificacoes() {
    showDialog<void>(
      context: context,
      builder:
          (context) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(22),
            ),
            title: const Row(
              children: [
                Icon(
                  Icons.notifications_none_rounded,
                  color: CoresHortasmart.verde,
                ),
                SizedBox(width: 10),
                Text('Notificações'),
              ],
            ),
            content: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 360),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 68,
                    height: 68,
                    decoration: BoxDecoration(
                      color: CoresHortasmart.verdeClaro,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Icon(
                      Icons.notifications_paused_outlined,
                      color: CoresHortasmart.verde,
                      size: 34,
                    ),
                  ),
                  const SizedBox(height: 18),
                  const Text(
                    'Central de notificações',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: CoresHortasmart.texto,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Esta área ainda será conectada aos alertas do sistema. '
                    'Quando estiver ativa, você poderá acompanhar avisos de '
                    'umidade, conexão do ESP32 e irrigação por aqui.',
                    textAlign: TextAlign.center,
                    style: TextStyle(height: 1.45, color: Color(0xFF6C7A72)),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Fechar'),
              ),
            ],
          ),
    );
  }

  /// Exibe os dados da conta autenticada no Firebase.
  void _abrirPerfil() {
    final usuario = FirebaseAuth.instance.currentUser;
    final nome = usuario?.displayName?.trim();
    final email = usuario?.email?.trim();
    final nomeExibicao =
        (nome != null && nome.isNotEmpty)
            ? nome
            : (email != null && email.contains('@')
                ? email.split('@').first
                : 'Usuário HortaSmart');
    final emailExibicao =
        (email != null && email.isNotEmpty) ? email : 'E-mail não disponível';
    final inicial = nomeExibicao.substring(0, 1).toUpperCase();

    showDialog<void>(
      context: context,
      builder:
          (context) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(22),
            ),
            title: const Text('Meu perfil'),
            content: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 380),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircleAvatar(
                    radius: 34,
                    backgroundColor: CoresHortasmart.verdeClaro,
                    child: Text(
                      inicial,
                      style: const TextStyle(
                        color: CoresHortasmart.verde,
                        fontSize: 26,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    nomeExibicao,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: CoresHortasmart.texto,
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    emailExibicao,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Color(0xFF6C7A72),
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 18),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 13,
                      vertical: 11,
                    ),
                    decoration: BoxDecoration(
                      color: CoresHortasmart.verdeClaro.withValues(alpha: 0.65),
                      borderRadius: BorderRadius.circular(13),
                    ),
                    child: const Row(
                      children: [
                        Icon(
                          Icons.verified_user_outlined,
                          color: CoresHortasmart.verde,
                          size: 19,
                        ),
                        SizedBox(width: 9),
                        Expanded(
                          child: Text(
                            'Conta conectada ao HortaSmart',
                            style: TextStyle(
                              color: CoresHortasmart.verde,
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Fechar'),
              ),
            ],
          ),
    );
  }

  /// Solicita confirmação antes de encerrar a sessão do Firebase.
  Future<void> _confirmarSaidaDaConta() async {
    final confirmou = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(22),
            ),
            title: const Text('Sair da conta?'),
            content: const Text(
              'Você precisará entrar novamente para acessar sua horta.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Cancelar'),
              ),
              FilledButton.icon(
                onPressed: () => Navigator.of(context).pop(true),
                style: FilledButton.styleFrom(
                  backgroundColor: CoresHortasmart.verde,
                  foregroundColor: Colors.white,
                ),
                icon: const Icon(Icons.logout_rounded, size: 18),
                label: const Text('Sair'),
              ),
            ],
          ),
    );

    if (confirmou != true) return;

    try {
      await FirebaseAuth.instance.signOut();
    } catch (erro) {
      debugPrint('Erro ao sair da conta: $erro');
      _mostrarMensagem('Não foi possível sair da conta. Tente novamente.');
    }
  }

  void _abrirConfiguracoes() {
    setState(() {
      _indiceSelecionado = RotasHortasmart.configuracoes;
    });
  }

  @override
  Widget build(BuildContext context) {
    final usuario = FirebaseAuth.instance.currentUser;
    final nomeFirebase = usuario?.displayName?.trim();
    final emailFirebase = usuario?.email?.trim() ?? '';
    final nomeUsuario =
        (nomeFirebase != null && nomeFirebase.isNotEmpty)
            ? nomeFirebase
            : (emailFirebase.isNotEmpty
                ? emailFirebase.split('@').first
                : 'Minha conta');

    final telas = [
      TelaPainel(
        canteiros: _canteiros,
        aoAbrirIrrigacao: () {
          setState(() {
            _indiceSelecionado = RotasHortasmart.irrigacao;
          });
        },
        aoAbrirCanteiro: (canteiro) {
          setState(() {
            _canteiroInicialIrrigacao = canteiro.id;
            _indiceSelecionado = RotasHortasmart.irrigacao;
          });
        },
        aoAlterarFoto: _abrirOpcoesFoto,
        aoAdicionarCanteiro: _adicionarCanteiro,
      ),
      TelaIrrigacao(
        canteiros: _canteiros,
        aoAtualizarCanteiro: _atualizarCanteiro,
        canteiroInicialId: _canteiroInicialIrrigacao,
      ),
      TelaHistorico(canteiros: _canteiros),
      TelaConfiguracoes(
        canteiros: _canteiros,
        aoAdicionarCanteiro: _adicionarCanteiro,
        aoAtualizarCanteiro: _atualizarCanteiro,
        aoRemoverCanteiro: _removerCanteiro,
      ),
    ];

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Color(0xFF075C39),
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final telaAmpla = constraints.maxWidth >= 820;

          return Scaffold(
            body: SafeArea(
              bottom: false,
              child: Row(
                children: [
                  if (telaAmpla)
                    Container(
                      width: constraints.maxWidth >= 1100 ? 230 : 108,
                      color: Colors.white,
                      child: Column(
                        children: [
                          if (constraints.maxWidth >= 1100)
                            Padding(
                              padding: const EdgeInsets.fromLTRB(
                                17,
                                20,
                                12,
                                18,
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    width: 40,
                                    height: 40,
                                    decoration: BoxDecoration(
                                      color: CoresHortasmart.verdeClaro,
                                      borderRadius: BorderRadius.circular(13),
                                    ),
                                    child: const Icon(
                                      Icons.eco_rounded,
                                      color: CoresHortasmart.verde,
                                      size: 25,
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  const Expanded(
                                    child: Text(
                                      'HortaSmart',
                                      style: TextStyle(
                                        fontWeight: FontWeight.w900,
                                        fontSize: 18,
                                        color: CoresHortasmart.texto,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            )
                          else
                            const SizedBox(height: 12),
                          const Divider(height: 1, color: Color(0xFFE8EEE9)),
                          Expanded(
                            child: NavigationRail(
                              selectedIndex: _indiceSelecionado,
                              onDestinationSelected: (indice) {
                                setState(() {
                                  _indiceSelecionado = indice;
                                });
                              },
                              extended: constraints.maxWidth >= 1100,
                              minWidth: constraints.maxWidth >= 1100 ? 72 : 108,
                              minExtendedWidth: 230,
                              labelType:
                                  constraints.maxWidth >= 1100
                                      ? NavigationRailLabelType.none
                                      : NavigationRailLabelType.all,
                              groupAlignment: -0.95,
                              backgroundColor: Colors.white,
                              indicatorColor: CoresHortasmart.verdeClaro,
                              destinations: const [
                                NavigationRailDestination(
                                  icon: Icon(Icons.grid_view_rounded),
                                  selectedIcon: Icon(Icons.grid_view_rounded),
                                  label: Text('Painel'),
                                ),
                                NavigationRailDestination(
                                  icon: Icon(Icons.water_drop_outlined),
                                  selectedIcon: Icon(Icons.water_drop_rounded),
                                  label: Text('Irrigação'),
                                ),
                                NavigationRailDestination(
                                  icon: Icon(
                                    Icons.insert_chart_outlined_rounded,
                                  ),
                                  selectedIcon: Icon(
                                    Icons.insert_chart_rounded,
                                  ),
                                  label: Text('Histórico'),
                                ),
                                NavigationRailDestination(
                                  icon: Icon(Icons.tune_rounded),
                                  selectedIcon: Icon(Icons.tune_rounded),
                                  label: Text('Configurações'),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  Expanded(
                    child: Column(
                      children: [
                        CabecalhoAplicativo(
                          indiceSelecionado: _indiceSelecionado,
                          nomeUsuario: nomeUsuario,
                          emailUsuario: emailFirebase,
                          aoAbrirNotificacoes: _abrirNotificacoes,
                          aoAbrirPerfil: _abrirPerfil,
                          aoAbrirConfiguracoes: _abrirConfiguracoes,
                          aoSair: _confirmarSaidaDaConta,
                        ),
                        Expanded(
                          child:
                              _carregando
                                  ? const Center(
                                    child: CircularProgressIndicator(),
                                  )
                                  : IndexedStack(
                                    index: _indiceSelecionado,
                                    children: telas,
                                  ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            bottomNavigationBar:
                telaAmpla
                    ? null
                    : NavigationBar(
                      elevation: 0,
                      backgroundColor: Colors.white,
                      indicatorColor: CoresHortasmart.verdeClaro,
                      labelBehavior:
                          NavigationDestinationLabelBehavior.alwaysShow,
                      selectedIndex: _indiceSelecionado,
                      onDestinationSelected: (indice) {
                        setState(() {
                          _indiceSelecionado = indice;
                        });
                      },
                      destinations: const [
                        NavigationDestination(
                          icon: Icon(Icons.grid_view_rounded),
                          selectedIcon: Icon(Icons.grid_view_rounded),
                          label: 'Painel',
                        ),
                        NavigationDestination(
                          icon: Icon(Icons.water_drop_outlined),
                          selectedIcon: Icon(Icons.water_drop_rounded),
                          label: 'Irrigação',
                        ),
                        NavigationDestination(
                          icon: Icon(Icons.insert_chart_outlined_rounded),
                          selectedIcon: Icon(Icons.insert_chart_rounded),
                          label: 'Histórico',
                        ),
                        NavigationDestination(
                          icon: Icon(Icons.tune_rounded),
                          selectedIcon: Icon(Icons.tune_rounded),
                          label: 'Configurações',
                        ),
                      ],
                    ),
          );
        },
      ),
    );
  }
}

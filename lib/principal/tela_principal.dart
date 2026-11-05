import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
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

  late List<Canteiro> _canteiros;

  final ImagePicker _seletorImagem = ImagePicker();

  @override
  void initState() {
    super.initState();

    _canteiros = RepositorioCanteiro.criarDadosDemonstracao();

    _carregarFotosSalvas();
  }

  // Lê o mapa de associações salvo no dispositivo.
  Future<Map<String, String>> _lerMapaFotos() async {
    final preferencias = await SharedPreferences.getInstance();

    final conteudo = preferencias.getString(_chaveFotos);

    if (conteudo == null || conteudo.isEmpty) {
      return {};
    }

    try {
      final decodificado = jsonDecode(conteudo);

      return Map<String, String>.from(decodificado);
    } catch (_) {
      return {};
    }
  }

  // Salva o mapa de IDs e caminhos das imagens.
  Future<void> _salvarMapaFotos(
    Map<String, String> fotos,
  ) async {
    final preferencias = await SharedPreferences.getInstance();

    await preferencias.setString(
      _chaveFotos,
      jsonEncode(fotos),
    );
  }

  // Recupera as imagens quando o aplicativo é aberto.
  Future<void> _carregarFotosSalvas() async {
    try {
      final fotosSalvas = await _lerMapaFotos();

      final canteirosAtualizados = <Canteiro>[];

      final fotosValidas = <String, String>{};

      for (final canteiro in _canteiros) {
        final caminho = fotosSalvas[canteiro.id];

        if (caminho == null || caminho.isEmpty) {
          canteirosAtualizados.add(canteiro);
          continue;
        }

        final arquivo = File(caminho);

        if (await arquivo.exists()) {
          fotosValidas[canteiro.id] = caminho;

          canteirosAtualizados.add(
            canteiro.copiarCom(caminhoImagem: caminho),
          );
        } else {
          canteirosAtualizados.add(canteiro);
        }
      }

      // Remove associações de arquivos que não existem mais.
      if (fotosValidas.length != fotosSalvas.length) {
        await _salvarMapaFotos(fotosValidas);
      }

      if (!mounted) return;

      setState(() {
        _canteiros = canteirosAtualizados;
      });
    } catch (erro) {
      debugPrint('Erro ao recuperar fotos: $erro');
    }
  }

  void _atualizarCanteiro(Canteiro atualizado) {
    setState(() {
      _canteiros = _canteiros
          .map(
            (canteiro) => canteiro.id == atualizado.id ? atualizado : canteiro,
          )
          .toList();
    });
  }

  Future<void> _selecionarFoto(
    Canteiro canteiro,
    ImageSource origem,
  ) async {
    try {
      final XFile? imagem = await _seletorImagem.pickImage(
        source: origem,
        imageQuality: 85,
        maxWidth: 1600,
      );

      if (imagem == null || !mounted) return;

      final diretorio = await getApplicationDocumentsDirectory();

      final nomeSeguro = canteiro.id.replaceAll(
        RegExp(r'[^a-zA-Z0-9_-]'),
        '_',
      );

      final extensao = imagem.name.contains('.')
          ? imagem.name.substring(imagem.name.lastIndexOf('.'))
          : '.jpg';

      final destino = '${diretorio.path}/canteiro_$nomeSeguro$extensao';

      final arquivo = await File(imagem.path).copy(destino);

      // Atualiza o mapa de fotos usando o ID do canteiro.
      final fotosSalvas = await _lerMapaFotos();

      fotosSalvas[canteiro.id] = arquivo.path;

      await _salvarMapaFotos(fotosSalvas);

      if (!mounted) return;

      final caminhoAntigo = canteiro.caminhoImagem;

      _atualizarCanteiro(
        canteiro.copiarCom(caminhoImagem: arquivo.path),
      );

      // Remove a imagem antiga caso tenha sido substituída.
      if (caminhoAntigo != null && caminhoAntigo != arquivo.path) {
        final arquivoAntigo = File(caminhoAntigo);

        if (await arquivoAntigo.exists()) {
          await arquivoAntigo.delete();
        }
      }

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Foto do canteiro atualizada!'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (erro) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Não foi possível selecionar a imagem: $erro'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _removerFoto(Canteiro canteiro) async {
    try {
      final caminho = canteiro.caminhoImagem;

      // Primeiro remove a associação salva.
      final fotosSalvas = await _lerMapaFotos();

      fotosSalvas.remove(canteiro.id);

      await _salvarMapaFotos(fotosSalvas);

      // Depois remove o arquivo físico.
      if (caminho != null) {
        final arquivo = File(caminho);

        if (await arquivo.exists()) {
          await arquivo.delete();
        }
      }

      if (!mounted) return;

      _atualizarCanteiro(
        canteiro.copiarCom(removerImagem: true),
      );

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Foto removida com sucesso.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (erro) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Não foi possível remover a foto: $erro'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _abrirOpcoesFoto(Canteiro canteiro) async {
    await showModalBottomSheet<void>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(22),
        ),
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
                if (canteiro.caminhoImagem != null)
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

  void _adicionarCanteiro(Canteiro novo) {
    setState(() {
      _canteiros = [..._canteiros, novo];
    });
  }

  void _removerCanteiro(String id) {
    setState(() {
      _canteiros = _canteiros.where((canteiro) => canteiro.id != id).toList();
    });
  }

  void _acaoCabecalho() {
    switch (_indiceSelecionado) {
      case 0:
        showDialog<void>(
          context: context,
          builder: (context) => AlertDialog(
            icon: const Icon(
              Icons.notifications_active_outlined,
              color: CoresHortasmart.verde,
              size: 30,
            ),
            title: const Text('Notificações'),
            content: const Text('Nenhuma notificação nova.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Entendi'),
              ),
            ],
          ),
        );
        break;

      case 1:
        setState(() {
          _indiceSelecionado = RotasHortasmart.configuracoes;
        });
        break;

      case 2:
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Altere o período pelos controles na tela de histórico.',
            ),
            behavior: SnackBarBehavior.floating,
          ),
        );
        break;

      default:
        showAboutDialog(
          context: context,
          applicationName: 'HortaSmart',
          applicationVersion: '1.1.0',
          applicationIcon: const Icon(
            Icons.eco_rounded,
            color: CoresHortasmart.verde,
            size: 36,
          ),
          children: const [
            Text(
              'Aplicativo de monitoramento e irrigação inteligente.',
            ),
          ],
        );
    }
  }

  @override
  Widget build(BuildContext context) {
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
                      width: constraints.maxWidth >= 1100 ? 230 : 86,
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
                          const Divider(
                            height: 1,
                            color: Color(0xFFE8EEE9),
                          ),
                          Expanded(
                            child: NavigationRail(
                              selectedIndex: _indiceSelecionado,
                              onDestinationSelected: (indice) {
                                setState(() {
                                  _indiceSelecionado = indice;
                                });
                              },
                              extended: constraints.maxWidth >= 1100,
                              minWidth: 72,
                              minExtendedWidth: 230,
                              labelType: NavigationRailLabelType.none,
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
                          aoVoltarPainel: () {
                            setState(() {
                              _indiceSelecionado = RotasHortasmart.painel;
                            });
                          },
                          aoAcionar: _acaoCabecalho,
                        ),
                        Expanded(
                          child: IndexedStack(
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
            bottomNavigationBar: telaAmpla
                ? null
                : NavigationBar(
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

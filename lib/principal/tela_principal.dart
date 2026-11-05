import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

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
  int _indiceSelecionado = RotasHortasmart.painel;
  String? _canteiroInicialIrrigacao;
  late List<Canteiro> _canteiros;

  @override
  void initState() {
    super.initState();
    _canteiros = RepositorioCanteiro.criarDadosDemonstracao();
  }

  void _atualizarCanteiro(Canteiro atualizado) {
    setState(() {
      _canteiros = _canteiros
          .map((canteiro) => canteiro.id == atualizado.id ? atualizado : canteiro)
          .toList();
    });
  }

  void _adicionarCanteiro(Canteiro novo) {
    setState(() => _canteiros = [..._canteiros, novo]);
  }

  void _removerCanteiro(String id) {
    setState(() => _canteiros = _canteiros.where((canteiro) => canteiro.id != id).toList());
  }

  void _acaoCabecalho() {
    switch (_indiceSelecionado) {
      case 0:
        showDialog<void>(
          context: context,
          builder: (context) => AlertDialog(
            icon: const Icon(Icons.notifications_active_outlined, color: CoresHortasmart.verde, size: 30),
            title: const Text('Notificações'),
            content: const Text('Não há notificações novas nesta prévia. Quando o Firebase estiver integrado, alertas de umidade poderão aparecer aqui.'),
            actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('Entendi'))],
          ),
        );
        break;
      case 1:
        setState(() => _indiceSelecionado = RotasHortasmart.configuracoes);
        break;
      case 2:
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Altere o período pelos controles na tela de histórico.'), behavior: SnackBarBehavior.floating),
        );
        break;
      default:
        showAboutDialog(
          context: context,
          applicationName: 'HortaSmart',
          applicationVersion: '1.0.0',
          applicationIcon: const Icon(Icons.eco_rounded, color: CoresHortasmart.verde, size: 36),
          children: const [Text('Protótipo de monitoramento e irrigação inteligente de hortas.')],
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final telas = [
      TelaPainel(
        canteiros: _canteiros,
        aoAbrirIrrigacao: () => setState(() => _indiceSelecionado = RotasHortasmart.irrigacao),
        aoAbrirCanteiro: (canteiro) => setState(() {
          _canteiroInicialIrrigacao = canteiro.id;
          _indiceSelecionado = RotasHortasmart.irrigacao;
        }),
      ),
      TelaIrrigacao(canteiros: _canteiros, aoAtualizarCanteiro: _atualizarCanteiro, canteiroInicialId: _canteiroInicialIrrigacao),
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
                              padding: const EdgeInsets.fromLTRB(17, 20, 12, 18),
                              child: Row(
                                children: [
                                  Container(
                                    width: 40,
                                    height: 40,
                                    decoration: BoxDecoration(color: CoresHortasmart.verdeClaro, borderRadius: BorderRadius.circular(13)),
                                    child: const Icon(Icons.eco_rounded, color: CoresHortasmart.verde, size: 25),
                                  ),
                                  const SizedBox(width: 10),
                                  const Expanded(
                                    child: Text('HortaSmart', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18, color: CoresHortasmart.texto)),
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
                              onDestinationSelected: (indice) => setState(() => _indiceSelecionado = indice),
                              extended: constraints.maxWidth >= 1100,
                              minWidth: 72,
                              minExtendedWidth: 230,
                              labelType: NavigationRailLabelType.none,
                              groupAlignment: -0.95,
                              backgroundColor: Colors.white,
                              indicatorColor: CoresHortasmart.verdeClaro,
                              destinations: const [
                                NavigationRailDestination(icon: Icon(Icons.grid_view_rounded), selectedIcon: Icon(Icons.grid_view_rounded), label: Text('Painel')),
                                NavigationRailDestination(icon: Icon(Icons.water_drop_outlined), selectedIcon: Icon(Icons.water_drop_rounded), label: Text('Irrigação')),
                                NavigationRailDestination(icon: Icon(Icons.insert_chart_outlined_rounded), selectedIcon: Icon(Icons.insert_chart_rounded), label: Text('Histórico')),
                                NavigationRailDestination(icon: Icon(Icons.tune_rounded), selectedIcon: Icon(Icons.tune_rounded), label: Text('Configurações')),
                              ],
                            ),
                          ),
                          if (constraints.maxWidth >= 1100)
                            const Padding(
                              padding: EdgeInsets.all(16),
                              child: Row(children: [Icon(Icons.wifi_rounded, size: 17, color: CoresHortasmart.verde), SizedBox(width: 7), Text('Modo de demonstração', style: TextStyle(fontSize: 11, color: CoresHortasmart.textoSecundario))]),
                            ),
                        ],
                      ),
                    ),
                  Expanded(
                    child: Column(
                      children: [
                        CabecalhoAplicativo(
                          indiceSelecionado: _indiceSelecionado,
                          aoVoltarPainel: () => setState(() => _indiceSelecionado = RotasHortasmart.painel),
                          aoAcionar: _acaoCabecalho,
                        ),
                        Expanded(
                          child: IndexedStack(index: _indiceSelecionado, children: telas),
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
                    onDestinationSelected: (indice) => setState(() => _indiceSelecionado = indice),
                    destinations: const [
                      NavigationDestination(icon: Icon(Icons.grid_view_rounded), selectedIcon: Icon(Icons.grid_view_rounded), label: 'Painel'),
                      NavigationDestination(icon: Icon(Icons.water_drop_outlined), selectedIcon: Icon(Icons.water_drop_rounded), label: 'Irrigação'),
                      NavigationDestination(icon: Icon(Icons.insert_chart_outlined_rounded), selectedIcon: Icon(Icons.insert_chart_rounded), label: 'Histórico'),
                      NavigationDestination(icon: Icon(Icons.tune_rounded), selectedIcon: Icon(Icons.tune_rounded), label: 'Configurações'),
                    ],
                  ),
          );
        },
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';

import '../../dados/modelos/canteiro.dart';
import '../../dados/modelos/previsao_tempo.dart';
import '../../dados/servicos/servico_clima.dart';
import '../../compartilhado/componentes/area_pagina.dart';
import '../../compartilhado/componentes/aviso_demonstracao.dart';
import '../../compartilhado/componentes/titulo_secao.dart';
import '../../compartilhado/constantes/cores.dart';
import 'cartao_canteiro.dart';
import 'estado_conexao.dart';

class TelaPainel extends StatelessWidget {
  const TelaPainel({
    super.key,
    required this.canteiros,
    required this.aoAbrirIrrigacao,
    required this.aoAbrirCanteiro,
  });

  final List<Canteiro> canteiros;
  final VoidCallback aoAbrirIrrigacao;
  final ValueChanged<Canteiro> aoAbrirCanteiro;

  @override
  Widget build(BuildContext context) {
    final conectados = canteiros.where((c) => c.conectado).length;
    final irrigando = canteiros.where((c) => c.irrigando).length;
    final criticos = canteiros.where((c) => c.umidadeAtual < 30).length;

    return AreaPagina(
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const AvisoDemonstracao(
              texto:
                  'Prévia visual: leituras e conexão ainda são dados demonstrativos.',
            ),
            const SizedBox(height: 13),
            EstadoConexao(
              dispositivosConectados: conectados,
              totalDispositivos: canteiros.length,
            ),
            const SizedBox(height: 12),
            _CartaoClima(irrigando: irrigando),
            const SizedBox(height: 22),
            TituloSecao(
              titulo: 'Canteiros da plantação',
              detalhe: '${canteiros.length} cadastrados',
            ),
            const SizedBox(height: 12),
            if (canteiros.isEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(26),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Column(
                  children: [
                    Icon(
                      Icons.grass_rounded,
                      size: 38,
                      color: CoresHortasmart.textoSecundario,
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Nenhum canteiro cadastrado',
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        color: CoresHortasmart.texto,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Abra Configurações para adicionar seu primeiro canteiro.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 12,
                        color: CoresHortasmart.textoSecundario,
                      ),
                    ),
                  ],
                ),
              )
            else
              LayoutBuilder(
                builder: (context, constraints) {
                  final colunas = constraints.maxWidth >= 760 ? 2 : 1;

                  return GridView.builder(
                    itemCount: canteiros.length,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: colunas,
                      mainAxisSpacing: 11,
                      crossAxisSpacing: 11,
                      mainAxisExtent: 148,
                    ),
                    itemBuilder: (context, indice) => CartaoCanteiro(
                      canteiro: canteiros[indice],
                      aoTocar: () => aoAbrirCanteiro(canteiros[indice]),
                    ),
                  );
                },
              ),
            const SizedBox(height: 18),
            if (criticos > 0)
              _AvisoCritico(
                quantidade: criticos,
                aoAbrirIrrigacao: aoAbrirIrrigacao,
              )
            else
              _CartaoAutomacao(aoAbrirIrrigacao: aoAbrirIrrigacao),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

class _CartaoClima extends StatefulWidget {
  const _CartaoClima({required this.irrigando});

  final int irrigando;

  @override
  State<_CartaoClima> createState() => _CartaoClimaState();
}

class _CartaoClimaState extends State<_CartaoClima> {
  final ServicoClima _servico = ServicoClima();
  final TextEditingController _cidadeController = TextEditingController();

  PrevisaoTempo? _previsao;
  bool _carregando = false;
  bool _buscandoLocalizacao = false;
  String? _erro;

  Future<void> _buscarClima() async {
    FocusScope.of(context).unfocus();

    setState(() {
      _carregando = true;
      _erro = null;
    });

    try {
      final resultado = await _servico.buscarPorCidade(
        _cidadeController.text,
      );

      if (!mounted) return;

      setState(() {
        _previsao = resultado;
        _cidadeController.text = resultado.cidade;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _erro = _mensagemErro(e);
      });
    } finally {
      if (mounted) {
        setState(() => _carregando = false);
      }
    }
  }

  Future<void> _buscarPelaLocalizacao() async {
    FocusScope.of(context).unfocus();

    setState(() {
      _buscandoLocalizacao = true;
      _erro = null;
    });

    try {
      final servicosAtivos = await Geolocator.isLocationServiceEnabled();

      if (!servicosAtivos) {
        throw Exception(
          'Ative a localização do dispositivo e tente novamente.',
        );
      }

      var permissao = await Geolocator.checkPermission();

      if (permissao == LocationPermission.denied) {
        permissao = await Geolocator.requestPermission();
      }

      if (permissao == LocationPermission.denied) {
        throw Exception(
          'A permissão de localização foi negada. Autorize para continuar.',
        );
      }

      if (permissao == LocationPermission.deniedForever) {
        throw Exception(
          'A localização está bloqueada nas permissões do sistema. '
          'Ative-a nas configurações do dispositivo.',
        );
      }

      final posicao = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.medium,
          timeLimit: Duration(seconds: 20),
        ),
      );

      if (!mounted) return;

      setState(() => _carregando = true);

      final resultado = await _servico.buscarPorCoordenadas(
        latitude: posicao.latitude,
        longitude: posicao.longitude,
      );

      if (!mounted) return;

      setState(() {
        _previsao = resultado;
        _cidadeController.text = resultado.cidade;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _erro = _mensagemErro(e);
      });
    } finally {
      if (mounted) {
        setState(() {
          _carregando = false;
          _buscandoLocalizacao = false;
        });
      }
    }
  }

  String _mensagemErro(Object erro) {
    return erro
        .toString()
        .replaceFirst('Exception: ', '')
        .replaceFirst('Invalid argument(s): ', '');
  }

  @override
  void dispose() {
    _cidadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final clima = _previsao;
    final ocupado = _carregando || _buscandoLocalizacao;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF172B3A),
        borderRadius: BorderRadius.circular(21),
        border: Border.all(color: const Color(0xFF2D4556)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF172B3A).withValues(alpha: 0.10),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(
                Icons.cloud_outlined,
                color: Color(0xFFB7D8E9),
                size: 19,
              ),
              SizedBox(width: 8),
              Text(
                'PREVISÃO DO TEMPO',
                style: TextStyle(
                  color: Color(0xFFD4E3EC),
                  fontSize: 10,
                  letterSpacing: 1.2,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 13),

          // Campo de cidade e botão de localização lado a lado.
          Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 46,
                  child: TextField(
                    controller: _cidadeController,
                    enabled: !ocupado,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                    ),
                    textInputAction: TextInputAction.search,
                    onSubmitted: (_) => _buscarClima(),
                    decoration: InputDecoration(
                      hintText: 'Digite uma cidade...',
                      hintStyle: const TextStyle(
                        color: Color(0xFFB8C9D5),
                        fontSize: 12,
                      ),
                      prefixIcon: const Icon(
                        Icons.search_rounded,
                        color: Color(0xFFD4E3EC),
                        size: 19,
                      ),
                      suffixIcon: IconButton(
                        tooltip: 'Pesquisar cidade',
                        onPressed: ocupado ? null : _buscarClima,
                        icon: const Icon(
                          Icons.arrow_forward_rounded,
                          color: Colors.white,
                          size: 19,
                        ),
                      ),
                      filled: true,
                      fillColor: const Color(0xFF263D4D),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 10,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(
                          color: Color(0xFF3C5668),
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(
                          color: Color(0xFF83D7F4),
                          width: 1.3,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              SizedBox(
                width: 46,
                height: 46,
                child: IconButton(
                  onPressed: ocupado ? null : _buscarPelaLocalizacao,
                  tooltip: 'Usar minha localização',
                  style: IconButton.styleFrom(
                    backgroundColor: const Color(0xFF247BA0),
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: const Color(0xFF405664),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  icon: _buscandoLocalizacao
                      ? const SizedBox(
                          width: 19,
                          height: 19,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.my_location_rounded, size: 21),
                ),
              ),
            ],
          ),

          const SizedBox(height: 15),

          if (ocupado)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(14),
                child: Column(
                  children: [
                    SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        color: Color(0xFF83D7F4),
                      ),
                    ),
                    SizedBox(height: 9),
                    Text(
                      'Consultando condições do tempo...',
                      style: TextStyle(
                        color: Color(0xFFD4E3EC),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            )
          else if (_erro != null)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(11),
              decoration: BoxDecoration(
                color: const Color(0xFF5A3038),
                borderRadius: BorderRadius.circular(11),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.info_outline_rounded,
                    color: Color(0xFFFFD2D2),
                    size: 19,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _erro!,
                      style: const TextStyle(
                        color: Color(0xFFFFE5E5),
                        fontSize: 12,
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            )
          else if (clima == null)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 9),
              child: Text(
                'Pesquise uma cidade ou toque no botão de localização '
                'para consultar o clima atual.',
                style: TextStyle(
                  color: Color(0xFFD4E3EC),
                  fontSize: 12,
                  height: 1.5,
                ),
              ),
            )
          else ...[
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(
                            Icons.location_on_outlined,
                            color: Color(0xFFB7D8E9),
                            size: 15,
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              '${clima.cidade}'
                              '${clima.pais.isNotEmpty ? ', ${clima.pais}' : ''}',
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Color(0xFFD4E3EC),
                                fontSize: 11,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '${clima.temperatura.round()}°C',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 37,
                          height: 1,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -1,
                        ),
                      ),
                      const SizedBox(height: 7),
                      Text(
                        clima.condicao,
                        style: const TextStyle(
                          color: Color(0xFFE4EEF4),
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Icon(
                  _iconeClima(clima.codigoClima),
                  color: _corIconeClima(clima.codigoClima),
                  size: 61,
                ),
              ],
            ),
            const SizedBox(height: 17),
            Container(
              height: 1,
              color: const Color(0xFF405664),
            ),
            const SizedBox(height: 13),
            LayoutBuilder(
              builder: (context, constraints) {
                final largura = (constraints.maxWidth - 24) / 3;

                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      width: largura,
                      child: _DadoClima(
                        icone: Icons.water_drop_outlined,
                        titulo: 'Umidade',
                        valor: '${clima.umidadeRelativa.round()}%',
                      ),
                    ),
                    SizedBox(
                      width: largura,
                      child: _DadoClima(
                        icone: Icons.cloud_outlined,
                        titulo: 'Chuva/hora',
                        valor: '${clima.probabilidadeChuva.round()}%',
                      ),
                    ),
                    SizedBox(
                      width: largura,
                      child: _DadoClima(
                        icone: Icons.air_rounded,
                        titulo: 'Vento',
                        valor: '${clima.velocidadeVento.round()} km/h',
                      ),
                    ),
                  ],
                );
              },
            ),
            const SizedBox(height: 13),
            Row(
              children: [
                const Icon(
                  Icons.access_time_rounded,
                  color: Color(0xFFB7D8E9),
                  size: 13,
                ),
                const SizedBox(width: 5),
                Expanded(
                  child: Text(
                    'Atualizado às '
                    '${clima.atualizadoEm.hour.toString().padLeft(2, '0')}:'
                    '${clima.atualizadoEm.minute.toString().padLeft(2, '0')}',
                    style: const TextStyle(
                      color: Color(0xFFB7D8E9),
                      fontSize: 10,
                    ),
                  ),
                ),
                const Icon(
                  Icons.eco_outlined,
                  color: Color(0xFF9ED7BB),
                  size: 14,
                ),
                const SizedBox(width: 4),
                Flexible(
                  child: Text(
                    '${widget.irrigando} '
                    '${widget.irrigando == 1 ? 'irrigando' : 'irrigando'}',
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Color(0xFFD4E3EC),
                      fontSize: 10,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  IconData _iconeClima(int codigo) {
    if (codigo == 0) return Icons.wb_sunny_rounded;
    if (codigo == 1 || codigo == 2) return Icons.cloud_queue_rounded;
    if (codigo == 3) return Icons.cloud_rounded;

    if (codigo == 45 || codigo == 48) {
      return Icons.foggy;
    }

    if ((codigo >= 51 && codigo <= 67) || (codigo >= 80 && codigo <= 82)) {
      return Icons.grain_rounded;
    }

    if (codigo >= 71 && codigo <= 77 || codigo == 85 || codigo == 86) {
      return Icons.ac_unit_rounded;
    }

    if (codigo >= 95) return Icons.thunderstorm_rounded;

    return Icons.cloud_rounded;
  }

  Color _corIconeClima(int codigo) {
    if (codigo == 0 || codigo == 1 || codigo == 2) {
      return const Color(0xFFF6CB76);
    }

    return const Color(0xFFB7DFF4);
  }
}

class _DadoClima extends StatelessWidget {
  const _DadoClima({
    required this.icone,
    required this.titulo,
    required this.valor,
  });

  final IconData icone;
  final String titulo;
  final String valor;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              icone,
              color: const Color(0xFF83D7F4),
              size: 15,
            ),
            const SizedBox(width: 4),
            Flexible(
              child: Text(
                titulo,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Color(0xFFB7D8E9),
                  fontSize: 9,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 5),
        Text(
          valor,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 13,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }
}

class _CartaoAutomacao extends StatelessWidget {
  const _CartaoAutomacao({required this.aoAbrirIrrigacao});

  final VoidCallback aoAbrirIrrigacao;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFEAF5ED),
        borderRadius: BorderRadius.circular(19),
        border: Border.all(color: const Color(0xFFD9EBDD)),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(13),
            ),
            child: const Icon(
              Icons.eco_rounded,
              color: CoresHortasmart.verde,
              size: 24,
            ),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Automação inteligente',
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    color: CoresHortasmart.texto,
                    fontSize: 13,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Defina a meta de umidade e a programação de cada canteiro.',
                  style: TextStyle(
                    fontSize: 11,
                    height: 1.35,
                    color: CoresHortasmart.textoSecundario,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: aoAbrirIrrigacao,
            tooltip: 'Configurar irrigação',
            icon: const Icon(
              Icons.arrow_forward_rounded,
              color: CoresHortasmart.verde,
            ),
          ),
        ],
      ),
    );
  }
}

class _AvisoCritico extends StatelessWidget {
  const _AvisoCritico({
    required this.quantidade,
    required this.aoAbrirIrrigacao,
  });

  final int quantidade;
  final VoidCallback aoAbrirIrrigacao;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: CoresHortasmart.vermelhoClaro,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFF5CECB)),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.warning_amber_rounded,
            color: CoresHortasmart.vermelho,
            size: 25,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              '$quantidade '
              '${quantidade == 1 ? 'canteiro está' : 'canteiros estão'} '
              'com umidade crítica. Confira as leituras antes de irrigar.',
              style: const TextStyle(
                color: CoresHortasmart.texto,
                fontSize: 12,
                height: 1.4,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          IconButton(
            onPressed: aoAbrirIrrigacao,
            tooltip: 'Abrir irrigação',
            icon: const Icon(
              Icons.arrow_forward_rounded,
              color: CoresHortasmart.vermelho,
            ),
          ),
        ],
      ),
    );
  }
}

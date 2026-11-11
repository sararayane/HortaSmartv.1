import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';

import '../../dados/modelos/canteiro.dart';
import '../../dados/modelos/previsao_tempo.dart';
import '../../dados/servicos/servico_clima.dart';
import '../../compartilhado/componentes/area_pagina.dart';
import '../../compartilhado/componentes/titulo_secao.dart';
import '../../compartilhado/constantes/cores.dart';
import '../configuracoes/formulario_canteiro.dart';
import 'cartao_canteiro.dart';

class TelaPainel extends StatelessWidget {
  const TelaPainel({
    super.key,
    required this.canteiros,
    required this.aoAbrirIrrigacao,
    required this.aoAbrirCanteiro,
    required this.aoAlterarFoto,
    required this.aoAdicionarCanteiro,
  });

  final List<Canteiro> canteiros;
  final VoidCallback aoAbrirIrrigacao;
  final ValueChanged<Canteiro> aoAbrirCanteiro;
  final ValueChanged<Canteiro> aoAlterarFoto;
  final ValueChanged<Canteiro> aoAdicionarCanteiro;

  Future<void> _abrirFormularioCanteiro(BuildContext context) async {
    final novoCanteiro = await showDialog<Canteiro>(
      context: context,
      builder: (_) => const FormularioCanteiro(),
    );

    if (novoCanteiro == null || !context.mounted) return;

    aoAdicionarCanteiro(novoCanteiro);
  }

  String _obterNomeUsuario() {
    final usuario = FirebaseAuth.instance.currentUser;
    final nome = usuario?.displayName?.trim() ?? '';

    if (nome.isNotEmpty) {
      return nome.split(RegExp(r'\s+')).first;
    }

    final email = usuario?.email?.trim() ?? '';
    if (email.isNotEmpty && email.contains('@')) {
      final identificador = email.split('@').first;
      if (identificador.isNotEmpty) return identificador;
    }

    return '';
  }

  @override
  Widget build(BuildContext context) {
    // Mantém os registros antigos de demonstração fora do painel.
    // Eles continuam armazenados no Firebase, sem serem excluídos.
    final canteirosDoUsuario =
        canteiros.where((canteiro) {
          return canteiro.id != 'canteiro-01' && canteiro.id != 'canteiro-02';
        }).toList();

    final nomeUsuario = _obterNomeUsuario();

    final sensoresConectados =
        canteirosDoUsuario.where((canteiro) => canteiro.conectado).length;

    final canteirosComLeitura =
        canteirosDoUsuario.where((canteiro) => canteiro.conectado).toList();

    final umidadeMedia =
        canteirosComLeitura.isEmpty
            ? null
            : canteirosComLeitura
                    .map((canteiro) => canteiro.umidadeAtual)
                    .reduce((a, b) => a + b) /
                canteirosComLeitura.length;

    final irrigando =
        canteirosDoUsuario.where((canteiro) => canteiro.irrigando).length;

    final canteirosCriticos =
        canteirosDoUsuario.where((canteiro) {
          return canteiro.conectado && canteiro.umidadeAtual < 30;
        }).length;

    final canteirosComAlerta =
        canteirosDoUsuario.where((canteiro) {
          return !canteiro.conectado ||
              canteiro.umidadeAtual < canteiro.metaUmidade;
        }).toList();

    return AreaPagina(
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _CartaoBoasVindas(nomeUsuario: nomeUsuario),
            const SizedBox(height: 16),

            _CartaoConectividade(
              total: canteirosDoUsuario.length,
              conectados: sensoresConectados,
            ),

            const SizedBox(height: 20),

            LayoutBuilder(
              builder: (context, constraints) {
                final colunas = constraints.maxWidth < 390 ? 2 : 4;
                const espacamento = 10.0;

                final larguraIndicador =
                    (constraints.maxWidth - espacamento * (colunas - 1)) /
                    colunas;

                final tamanhoCirculo =
                    (larguraIndicador * 0.72).clamp(42.0, 60.0).toDouble();

                final indicadores = [
                  _CartaoIndicador(
                    titulo: 'Canteiros',
                    valor: '${canteirosDoUsuario.length}',
                    icone: Icons.spa_outlined,
                    cor: CoresHortasmart.verde,
                    tamanhoCirculo: tamanhoCirculo,
                  ),
                  _CartaoIndicador(
                    titulo: 'Umidade',
                    valor:
                        umidadeMedia == null ? '—' : '${umidadeMedia.round()}%',
                    icone: Icons.water_drop_outlined,
                    cor: const Color(0xFF247BA0),
                    tamanhoCirculo: tamanhoCirculo,
                  ),
                  _CartaoIndicador(
                    titulo: 'Irrigando',
                    valor: '$irrigando',
                    icone: Icons.opacity_rounded,
                    cor: const Color(0xFF2787B7),
                    tamanhoCirculo: tamanhoCirculo,
                  ),
                  _CartaoIndicador(
                    titulo: 'Alertas',
                    valor: '${canteirosComAlerta.length}',
                    icone: Icons.notifications_active_outlined,
                    cor:
                        canteirosComAlerta.isEmpty
                            ? CoresHortasmart.verde
                            : const Color(0xFFB7791F),
                    tamanhoCirculo: tamanhoCirculo,
                  ),
                ];

                return Wrap(
                  spacing: espacamento,
                  runSpacing: 12,
                  children: [
                    for (final indicador in indicadores)
                      SizedBox(width: larguraIndicador, child: indicador),
                  ],
                );
              },
            ),

            const SizedBox(height: 25),

            TituloSecao(
              titulo: 'Minha plantação',
              detalhe:
                  '${canteirosDoUsuario.length} '
                  '${canteirosDoUsuario.length == 1 ? 'canteiro cadastrado' : 'canteiros cadastrados'}',
            ),

            const SizedBox(height: 12),

            if (canteirosDoUsuario.isEmpty)
              _EstadoVazioCanteiros(
                aoAdicionar: () => _abrirFormularioCanteiro(context),
              )
            else
              LayoutBuilder(
                builder: (context, constraints) {
                  // Duas colunas somente quando cada cartão tiver largura
                  // suficiente para acomodar texto, foto e ações sem cortes.
                  final colunas = constraints.maxWidth >= 820 ? 2 : 1;

                  final alturaBase = constraints.maxWidth < 380 ? 190.0 : 176.0;

                  final escalaTexto = MediaQuery.textScalerOf(
                    context,
                  ).scale(1.0);

                  final alturaCartao =
                      (alturaBase * escalaTexto.clamp(1.0, 1.8)).toDouble();

                  return GridView.builder(
                    itemCount: canteirosDoUsuario.length + 1,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: colunas,
                      mainAxisSpacing: 11,
                      crossAxisSpacing: 11,
                      mainAxisExtent: alturaCartao,
                    ),
                    itemBuilder: (context, indice) {
                      if (indice == canteirosDoUsuario.length) {
                        return _CartaoAdicionarCanteiro(
                          aoTocar: () => _abrirFormularioCanteiro(context),
                        );
                      }

                      final canteiro = canteirosDoUsuario[indice];

                      return CartaoCanteiro(
                        canteiro: canteiro,
                        aoTocar: () => aoAbrirCanteiro(canteiro),
                        aoAlterarFoto: () => aoAlterarFoto(canteiro),
                      );
                    },
                  );
                },
              ),

            const SizedBox(height: 24),

            TituloSecao(
              titulo: 'Alertas e cuidados',
              detalhe:
                  canteirosComAlerta.isEmpty
                      ? 'Nenhum alerta no momento'
                      : '${canteirosComAlerta.length} '
                          '${canteirosComAlerta.length == 1 ? 'canteiro em atenção' : 'canteiros em atenção'}',
            ),

            const SizedBox(height: 12),

            _CartaoAlertas(
              canteirosComAlerta: canteirosComAlerta,
              quantidadeCritica: canteirosCriticos,
              aoAbrirCanteiro: aoAbrirCanteiro,
              aoAbrirIrrigacao: aoAbrirIrrigacao,
            ),

            const SizedBox(height: 24),

            const TituloSecao(
              titulo: 'Acesso rápido',
              detalhe: 'As ações mais usadas da sua horta',
            ),

            const SizedBox(height: 12),

            LayoutBuilder(
              builder: (context, constraints) {
                final emDuasColunas = constraints.maxWidth >= 620;

                final acoes = [
                  _CartaoAcaoRapida(
                    titulo: 'Controlar irrigação',
                    descricao: 'Ajuste o modo e a meta de umidade',
                    icone: Icons.water_drop_rounded,
                    cor: const Color(0xFF247BA0),
                    aoTocar: aoAbrirIrrigacao,
                  ),
                  _CartaoAcaoRapida(
                    titulo: 'Adicionar canteiro',
                    descricao: 'Cadastre uma nova área de plantação',
                    icone: Icons.add_circle_outline_rounded,
                    cor: CoresHortasmart.verde,
                    aoTocar: () => _abrirFormularioCanteiro(context),
                  ),
                ];

                if (!emDuasColunas) {
                  return Column(
                    children: [
                      for (final acao in acoes) ...[
                        acao,
                        const SizedBox(height: 10),
                      ],
                    ],
                  );
                }

                return Row(
                  children: [
                    Expanded(child: acoes[0]),
                    const SizedBox(width: 11),
                    Expanded(child: acoes[1]),
                  ],
                );
              },
            ),

            const SizedBox(height: 24),

            // O cartão de clima continua aqui.
            // Somente o título "Clima da sua região" foi retirado.
            _CartaoClima(irrigando: irrigando),

            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

class _CartaoBoasVindas extends StatelessWidget {
  const _CartaoBoasVindas({required this.nomeUsuario});

  final String nomeUsuario;

  @override
  Widget build(BuildContext context) {
    final saudacao = nomeUsuario.isEmpty ? 'Olá!' : 'Olá, $nomeUsuario!';

    return LayoutBuilder(
      builder: (context, constraints) {
        final compacto = constraints.maxWidth < 360;
        final padding = compacto ? 16.0 : 21.0;
        final tamanhoTitulo = compacto ? 23.0 : 26.0;

        return ClipRRect(
          borderRadius: BorderRadius.circular(22),
          child: Container(
            width: double.infinity,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF087B4B), Color(0xFF05643D)],
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF075C39).withValues(alpha: 0.14),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Stack(
              children: [
                Positioned(
                  top: -48,
                  right: -24,
                  child: Container(
                    width: 142,
                    height: 142,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.09),
                        width: 22,
                      ),
                    ),
                  ),
                ),
                Positioned(
                  right: 70,
                  bottom: -64,
                  child: Container(
                    width: 112,
                    height: 112,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withValues(alpha: 0.045),
                    ),
                  ),
                ),
                Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: padding,
                    vertical: compacto ? 18 : 21,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        saudacao,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: tamanhoTitulo,
                          height: 1.15,
                          letterSpacing: -0.55,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Acompanhe tudo em um só lugar.',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: Color(0xFFE5F4EB),
                          fontSize: 13,
                          height: 1.45,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _CartaoConectividade extends StatelessWidget {
  const _CartaoConectividade({required this.total, required this.conectados});

  final int total;
  final int conectados;

  @override
  Widget build(BuildContext context) {
    final desconectados = total - conectados;
    final todosConectados = total > 0 && desconectados == 0;
    final nenhumConectado = total > 0 && conectados == 0;

    final cor =
        total == 0
            ? const Color(0xFF718078)
            : todosConectados
            ? CoresHortasmart.verde
            : const Color(0xFFB7791F);

    final titulo =
        total == 0
            ? 'Nenhum sensor cadastrado'
            : todosConectados
            ? 'Sensores conectados'
            : nenhumConectado
            ? 'Nenhum sensor conectado'
            : 'Conexão parcial';

    final descricao =
        total == 0
            ? 'Cadastre um canteiro para acompanhar os sensores.'
            : todosConectados
            ? 'Todos os sensores dos canteiros aparecem conectados.'
            : '$conectados de $total sensores conectados · $desconectados '
                '${desconectados == 1 ? 'desconectado' : 'desconectados'}';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFF0F7F1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFDCEBDF)),
      ),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
            child: Icon(
              todosConectados ? Icons.wifi_rounded : Icons.wifi_off_rounded,
              color: cor,
              size: 18,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  titulo,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: CoresHortasmart.texto,
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  descricao,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: CoresHortasmart.textoSecundario,
                    fontSize: 11,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Container(
            width: 9,
            height: 9,
            decoration: BoxDecoration(color: cor, shape: BoxShape.circle),
          ),
        ],
      ),
    );
  }
}

class _CartaoIndicador extends StatelessWidget {
  const _CartaoIndicador({
    required this.titulo,
    required this.valor,
    required this.icone,
    required this.cor,
    required this.tamanhoCirculo,
  });

  final String titulo;
  final String valor;
  final IconData icone;
  final Color cor;
  final double tamanhoCirculo;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: tamanhoCirculo,
          height: tamanhoCirculo,
          decoration: BoxDecoration(
            color: cor.withValues(alpha: 0.085),
            shape: BoxShape.circle,
            border: Border.all(color: cor.withValues(alpha: 0.16), width: 1),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icone, color: cor, size: tamanhoCirculo < 55 ? 14 : 16),
              const SizedBox(height: 2),
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  valor,
                  style: TextStyle(
                    color: cor,
                    fontSize: tamanhoCirculo < 55 ? 14 : 16,
                    height: 1.05,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 6),
        SizedBox(
          width: double.infinity,
          child: Text(
            titulo,
            maxLines: 2,
            textAlign: TextAlign.center,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: CoresHortasmart.textoSecundario,
              fontSize: 9,
              height: 1.15,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }
}

class _EstadoVazioCanteiros extends StatelessWidget {
  const _EstadoVazioCanteiros({required this.aoAdicionar});

  final VoidCallback aoAdicionar;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(19),
        border: Border.all(color: const Color(0xFFE1EAE3)),
      ),
      child: Column(
        children: [
          Container(
            width: 58,
            height: 58,
            decoration: BoxDecoration(
              color: CoresHortasmart.verdeClaro,
              borderRadius: BorderRadius.circular(18),
            ),
            child: const Icon(
              Icons.spa_outlined,
              color: CoresHortasmart.verde,
              size: 30,
            ),
          ),
          const SizedBox(height: 13),
          const Text(
            'Sua plantação começa aqui',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: CoresHortasmart.texto,
              fontSize: 15,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Cadastre seu primeiro canteiro para acompanhar a umidade e organizar a irrigação.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: CoresHortasmart.textoSecundario,
              fontSize: 12,
              height: 1.45,
            ),
          ),
          const SizedBox(height: 16),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 320),
            child: SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: aoAdicionar,
                style: FilledButton.styleFrom(
                  backgroundColor: CoresHortasmart.verde,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                icon: const Icon(Icons.add_rounded, size: 19),
                label: const Text(
                  'Adicionar primeiro canteiro',
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CartaoAdicionarCanteiro extends StatelessWidget {
  const _CartaoAdicionarCanteiro({required this.aoTocar});

  final VoidCallback aoTocar;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFFF7FAF7),
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: aoTocar,
        borderRadius: BorderRadius.circular(18),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final compacto = constraints.maxWidth < 300;

            final icone = Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: CoresHortasmart.verdeClaro,
                borderRadius: BorderRadius.circular(13),
              ),
              child: const Icon(
                Icons.add_rounded,
                color: CoresHortasmart.verde,
                size: 25,
              ),
            );

            const textos = Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Adicionar canteiro',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: CoresHortasmart.texto,
                    fontWeight: FontWeight.w800,
                    fontSize: 12,
                    height: 1.2,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Cadastre uma nova plantação',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: CoresHortasmart.textoSecundario,
                    fontSize: 10,
                    height: 1.25,
                  ),
                ),
              ],
            );

            return Container(
              width: double.infinity,
              padding: EdgeInsets.symmetric(
                horizontal: compacto ? 10 : 13,
                vertical: 12,
              ),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: CoresHortasmart.verde.withValues(alpha: 0.34),
                  width: 1.2,
                ),
              ),
              child:
                  compacto
                      ? Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          icone,
                          const SizedBox(height: 8),
                          const Center(child: textos),
                        ],
                      )
                      : Row(
                        children: [
                          icone,
                          const SizedBox(width: 11),
                          const Expanded(child: textos),
                          const SizedBox(width: 5),
                          const Icon(
                            Icons.arrow_forward_rounded,
                            color: CoresHortasmart.verde,
                            size: 19,
                          ),
                        ],
                      ),
            );
          },
        ),
      ),
    );
  }
}

class _CartaoAlertas extends StatelessWidget {
  const _CartaoAlertas({
    required this.canteirosComAlerta,
    required this.quantidadeCritica,
    required this.aoAbrirCanteiro,
    required this.aoAbrirIrrigacao,
  });

  final List<Canteiro> canteirosComAlerta;
  final int quantidadeCritica;
  final ValueChanged<Canteiro> aoAbrirCanteiro;
  final VoidCallback aoAbrirIrrigacao;

  String _descricaoAlerta(Canteiro canteiro) {
    if (!canteiro.conectado) return 'Sensor sem conexão';

    if (canteiro.umidadeAtual < 30) {
      return 'Umidade crítica · ${canteiro.umidadeAtual.round()}%';
    }

    return 'Abaixo da meta · ${canteiro.umidadeAtual.round()}% de '
        '${canteiro.metaUmidade.round()}%';
  }

  @override
  Widget build(BuildContext context) {
    final possuiAlertas = canteirosComAlerta.isNotEmpty;

    final corDestaque =
        possuiAlertas ? const Color(0xFFB7791F) : CoresHortasmart.verde;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 11),
      decoration: BoxDecoration(
        color:
            possuiAlertas ? const Color(0xFFFFFAF1) : const Color(0xFFF0F7F1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color:
              possuiAlertas ? const Color(0xFFF0E1C8) : const Color(0xFFDCEBDF),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          LayoutBuilder(
            builder: (context, constraints) {
              final titulo = Row(
                children: [
                  Icon(
                    possuiAlertas
                        ? Icons.warning_amber_rounded
                        : Icons.check_circle_outline_rounded,
                    color: corDestaque,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      possuiAlertas
                          ? quantidadeCritica > 0
                              ? '$quantidadeCritica '
                                  '${quantidadeCritica == 1 ? 'canteiro crítico' : 'canteiros críticos'}'
                              : 'Alguns canteiros precisam de atenção'
                          : 'Tudo em ordem por enquanto',
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color:
                            possuiAlertas
                                ? const Color(0xFF684A1D)
                                : CoresHortasmart.texto,
                        fontSize: 11,
                        height: 1.25,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ],
              );

              final botao = TextButton.icon(
                onPressed: aoAbrirIrrigacao,
                style: TextButton.styleFrom(
                  foregroundColor:
                      possuiAlertas
                          ? const Color(0xFF8A5D1B)
                          : CoresHortasmart.verde,
                  visualDensity: VisualDensity.compact,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 6,
                  ),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                icon: const Icon(Icons.tune_rounded, size: 15),
                label: const Text(
                  'Abrir irrigação',
                  maxLines: 1,
                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700),
                ),
              );

              if (constraints.maxWidth < 360) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    titulo,
                    Align(alignment: Alignment.centerRight, child: botao),
                  ],
                );
              }

              return Row(
                children: [
                  Expanded(child: titulo),
                  const SizedBox(width: 5),
                  botao,
                ],
              );
            },
          ),
          if (!possuiAlertas) ...[
            const SizedBox(height: 4),
            const Padding(
              padding: EdgeInsets.only(left: 28),
              child: Text(
                'Nenhum canteiro está abaixo da meta ou sem conexão registrada.',
                style: TextStyle(
                  color: CoresHortasmart.textoSecundario,
                  fontSize: 10,
                  height: 1.35,
                ),
              ),
            ),
          ] else ...[
            const SizedBox(height: 7),
            for (final canteiro in canteirosComAlerta.take(2))
              InkWell(
                onTap: () => aoAbrirCanteiro(canteiro),
                borderRadius: BorderRadius.circular(9),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 5),
                  child: Row(
                    children: [
                      Icon(
                        canteiro.conectado
                            ? Icons.water_drop_outlined
                            : Icons.wifi_off_rounded,
                        color: corDestaque,
                        size: 16,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          '${canteiro.nome} · ${_descricaoAlerta(canteiro)}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: CoresHortasmart.texto,
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      const Icon(
                        Icons.chevron_right_rounded,
                        color: Color(0xFF9B773F),
                        size: 17,
                      ),
                    ],
                  ),
                ),
              ),
            if (canteirosComAlerta.length > 2)
              Padding(
                padding: const EdgeInsets.only(left: 24, top: 3),
                child: Text(
                  '+ ${canteirosComAlerta.length - 2} '
                  '${canteirosComAlerta.length - 2 == 1 ? 'outro canteiro' : 'outros canteiros'}',
                  style: const TextStyle(
                    color: Color(0xFF795C31),
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
          ],
        ],
      ),
    );
  }
}

class _CartaoAcaoRapida extends StatelessWidget {
  const _CartaoAcaoRapida({
    required this.titulo,
    required this.descricao,
    required this.icone,
    required this.cor,
    required this.aoTocar,
  });

  final String titulo;
  final String descricao;
  final IconData icone;
  final Color cor;
  final VoidCallback aoTocar;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(17),
      child: InkWell(
        onTap: aoTocar,
        borderRadius: BorderRadius.circular(17),
        child: Container(
          constraints: const BoxConstraints(minHeight: 78),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(17),
            border: Border.all(color: const Color(0xFFE5ECE7)),
          ),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: cor.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(13),
                ),
                child: Icon(icone, color: cor, size: 22),
              ),
              const SizedBox(width: 11),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      titulo,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: CoresHortasmart.texto,
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      descricao,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: CoresHortasmart.textoSecundario,
                        fontSize: 10,
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 5),
              Icon(Icons.arrow_forward_ios_rounded, color: cor, size: 15),
            ],
          ),
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
  final FocusNode _cidadeFocus = FocusNode();

  Timer? _temporizadorPesquisa;

  PrevisaoTempo? _previsao;
  List<CidadeClima> _sugestoes = [];

  bool _carregando = false;
  bool _buscandoLocalizacao = false;
  bool _pesquisandoCidades = false;
  bool _mostrarSugestoes = false;

  String? _erro;
  int _versaoPesquisa = 0;

  void _aoDigitarCidade(String texto) {
    _temporizadorPesquisa?.cancel();
    final versao = ++_versaoPesquisa;

    if (texto.trim().length < 2) {
      setState(() {
        _sugestoes = [];
        _mostrarSugestoes = false;
        _pesquisandoCidades = false;
      });
      return;
    }

    setState(() {
      _mostrarSugestoes = true;
      _pesquisandoCidades = true;
      _erro = null;
    });

    _temporizadorPesquisa = Timer(
      const Duration(milliseconds: 450),
      () => _pesquisarCidades(texto, versao),
    );
  }

  Future<void> _pesquisarCidades(String texto, int versao) async {
    try {
      final resultados = await _servico.buscarCidades(texto);

      if (!mounted || versao != _versaoPesquisa) return;

      setState(() {
        _sugestoes = resultados;
        _pesquisandoCidades = false;
      });
    } catch (erro) {
      if (!mounted || versao != _versaoPesquisa) return;

      setState(() {
        _sugestoes = [];
        _pesquisandoCidades = false;
        _erro = _mensagemErro(erro);
      });
    }
  }

  Future<void> _selecionarCidade(CidadeClima cidade) async {
    FocusScope.of(context).unfocus();
    _temporizadorPesquisa?.cancel();
    _versaoPesquisa++;

    setState(() {
      _cidadeController.text = cidade.nome;
      _mostrarSugestoes = false;
      _sugestoes = [];
      _carregando = true;
      _erro = null;
    });

    try {
      final resultado = await _servico.buscarPorCidadeSelecionada(cidade);

      if (!mounted) return;

      setState(() {
        _previsao = resultado;
      });
    } catch (erro) {
      if (!mounted) return;

      setState(() {
        _erro = _mensagemErro(erro);
      });
    } finally {
      if (mounted) setState(() => _carregando = false);
    }
  }

  Future<void> _buscarPelaLocalizacao() async {
    FocusScope.of(context).unfocus();
    _temporizadorPesquisa?.cancel();
    _versaoPesquisa++;

    setState(() {
      _mostrarSugestoes = false;
      _sugestoes = [];
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

      final resultado = await _servico.buscarPorCoordenadas(
        latitude: posicao.latitude,
        longitude: posicao.longitude,
      );

      if (!mounted) return;

      setState(() {
        _previsao = resultado;
        _cidadeController.text = resultado.cidade;
      });
    } catch (erro) {
      if (!mounted) return;

      setState(() {
        _erro = _mensagemErro(erro);
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
    _temporizadorPesquisa?.cancel();
    _cidadeController.dispose();
    _cidadeFocus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final clima = _previsao;
    final ocupado = _carregando || _buscandoLocalizacao;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(17),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2EAE4)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x07052F1D),
            blurRadius: 14,
            offset: Offset(0, 4),
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
                color: CoresHortasmart.verde,
                size: 20,
              ),
              SizedBox(width: 8),
              Text(
                'PREVISÃO DO TEMPO',
                style: TextStyle(
                  color: CoresHortasmart.verde,
                  fontSize: 10,
                  letterSpacing: 1.15,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),

          const SizedBox(height: 13),

          LayoutBuilder(
            builder: (context, constraints) {
              final campoCidade = ConstrainedBox(
                constraints: const BoxConstraints(minHeight: 46),
                child: TextField(
                  controller: _cidadeController,
                  focusNode: _cidadeFocus,
                  enabled: !ocupado,
                  onChanged: _aoDigitarCidade,
                  style: const TextStyle(
                    color: CoresHortasmart.texto,
                    fontSize: 13,
                  ),
                  textInputAction: TextInputAction.search,
                  decoration: InputDecoration(
                    hintText: 'Digite uma cidade...',
                    hintStyle: const TextStyle(
                      color: Color(0xFF89968F),
                      fontSize: 12,
                    ),
                    prefixIcon: const Icon(
                      Icons.search_rounded,
                      color: CoresHortasmart.verde,
                      size: 19,
                    ),
                    suffixIcon:
                        _pesquisandoCidades
                            ? const Padding(
                              padding: EdgeInsets.all(13),
                              child: SizedBox(
                                width: 17,
                                height: 17,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: CoresHortasmart.verde,
                                ),
                              ),
                            )
                            : null,
                    filled: true,
                    fillColor: const Color(0xFFF5F8F5),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 13,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xFFE1EAE3)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(
                        color: CoresHortasmart.verde,
                        width: 1.3,
                      ),
                    ),
                  ),
                ),
              );

              final botaoLocalizacao = SizedBox(
                width: 46,
                height: 46,
                child: IconButton(
                  onPressed: ocupado ? null : _buscarPelaLocalizacao,
                  tooltip: 'Usar minha localização',
                  style: IconButton.styleFrom(
                    backgroundColor: CoresHortasmart.verde,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: const Color(0xFFB6C9BC),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  icon:
                      _buscandoLocalizacao
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
              );

              if (constraints.maxWidth < 340) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    campoCidade,
                    const SizedBox(height: 8),
                    Align(
                      alignment: Alignment.centerRight,
                      child: botaoLocalizacao,
                    ),
                  ],
                );
              }

              return Row(
                children: [
                  Expanded(child: campoCidade),
                  const SizedBox(width: 8),
                  botaoLocalizacao,
                ],
              );
            },
          ),

          if (_mostrarSugestoes && !ocupado) ...[
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAF8),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE1EAE3)),
              ),
              child:
                  _pesquisandoCidades
                      ? const Padding(
                        padding: EdgeInsets.all(13),
                        child: Row(
                          children: [
                            SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: CoresHortasmart.verde,
                              ),
                            ),
                            SizedBox(width: 10),
                            Text(
                              'Buscando cidades...',
                              style: TextStyle(
                                color: CoresHortasmart.textoSecundario,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      )
                      : _sugestoes.isEmpty
                      ? const Padding(
                        padding: EdgeInsets.all(13),
                        child: Text(
                          'Nenhuma cidade encontrada.',
                          style: TextStyle(
                            color: CoresHortasmart.textoSecundario,
                            fontSize: 12,
                          ),
                        ),
                      )
                      : Column(
                        mainAxisSize: MainAxisSize.min,
                        children:
                            _sugestoes.map((cidade) {
                              return InkWell(
                                borderRadius: BorderRadius.circular(10),
                                onTap:
                                    ocupado
                                        ? null
                                        : () => _selecionarCidade(cidade),
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 11,
                                  ),
                                  child: Row(
                                    children: [
                                      const Icon(
                                        Icons.location_on_outlined,
                                        color: CoresHortasmart.verde,
                                        size: 19,
                                      ),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              cidade.nome,
                                              style: const TextStyle(
                                                color: CoresHortasmart.texto,
                                                fontSize: 12,
                                                fontWeight: FontWeight.w700,
                                              ),
                                            ),
                                            if (cidade.descricao.isNotEmpty)
                                              Text(
                                                cidade.descricao,
                                                style: const TextStyle(
                                                  color:
                                                      CoresHortasmart
                                                          .textoSecundario,
                                                  fontSize: 10,
                                                ),
                                              ),
                                          ],
                                        ),
                                      ),
                                      const Icon(
                                        Icons.chevron_right_rounded,
                                        color: Color(0xFF8A9A90),
                                        size: 19,
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            }).toList(),
                      ),
            ),
          ],

          const SizedBox(height: 16),

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
                        color: CoresHortasmart.verde,
                      ),
                    ),
                    SizedBox(height: 9),
                    Text(
                      'Consultando condições do tempo...',
                      style: TextStyle(
                        color: CoresHortasmart.textoSecundario,
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
                color: const Color(0xFFFFF0EE),
                borderRadius: BorderRadius.circular(11),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.info_outline_rounded,
                    color: Color(0xFFB5473C),
                    size: 19,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _erro!,
                      style: const TextStyle(
                        color: Color(0xFF873B34),
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
                'Pesquise uma cidade ou use sua localização para consultar o clima atual.',
                style: TextStyle(
                  color: CoresHortasmart.textoSecundario,
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
                            color: CoresHortasmart.textoSecundario,
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
                                color: CoresHortasmart.textoSecundario,
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
                          color: CoresHortasmart.texto,
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
                          color: CoresHortasmart.texto,
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
                  size: MediaQuery.sizeOf(context).width < 400 ? 44 : 56,
                ),
              ],
            ),

            const SizedBox(height: 17),

            Container(height: 1, color: const Color(0xFFE8EEE9)),

            const SizedBox(height: 13),

            LayoutBuilder(
              builder: (context, constraints) {
                final colunas = constraints.maxWidth < 340 ? 2 : 3;
                const espacamento = 10.0;

                final largura =
                    (constraints.maxWidth - espacamento * (colunas - 1)) /
                    colunas;

                final dados = [
                  _DadoClima(
                    icone: Icons.water_drop_outlined,
                    titulo: 'Umidade',
                    valor: '${clima.umidadeRelativa.round()}%',
                  ),
                  _DadoClima(
                    icone: Icons.cloud_outlined,
                    titulo: 'Chuva',
                    valor: '${clima.probabilidadeChuva.round()}%',
                  ),
                  _DadoClima(
                    icone: Icons.air_rounded,
                    titulo: 'Vento',
                    valor: '${clima.velocidadeVento.round()} km/h',
                  ),
                ];

                return Wrap(
                  spacing: espacamento,
                  runSpacing: 12,
                  children: [
                    for (final dado in dados)
                      SizedBox(width: largura, child: dado),
                  ],
                );
              },
            ),

            const SizedBox(height: 13),

            Wrap(
              spacing: 12,
              runSpacing: 7,
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.access_time_rounded,
                      color: CoresHortasmart.textoSecundario,
                      size: 13,
                    ),
                    const SizedBox(width: 5),
                    Text(
                      'Atualizado às '
                      '${clima.atualizadoEm.hour.toString().padLeft(2, '0')}:'
                      '${clima.atualizadoEm.minute.toString().padLeft(2, '0')}',
                      style: const TextStyle(
                        color: CoresHortasmart.textoSecundario,
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.eco_outlined,
                      color: CoresHortasmart.verde,
                      size: 14,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${widget.irrigando} '
                      '${widget.irrigando == 1 ? 'canteiro irrigando' : 'canteiros irrigando'}',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: CoresHortasmart.textoSecundario,
                        fontSize: 10,
                      ),
                    ),
                  ],
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

    if (codigo == 45 || codigo == 48) return Icons.foggy;

    if ((codigo >= 51 && codigo <= 67) || (codigo >= 80 && codigo <= 82)) {
      return Icons.grain_rounded;
    }

    if ((codigo >= 71 && codigo <= 77) || codigo == 85 || codigo == 86) {
      return Icons.ac_unit_rounded;
    }

    if (codigo >= 95) return Icons.thunderstorm_rounded;

    return Icons.cloud_rounded;
  }

  Color _corIconeClima(int codigo) {
    if (codigo == 0 || codigo == 1 || codigo == 2) {
      return const Color(0xFFE4AC42);
    }

    return const Color(0xFF5E9B83);
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
            Icon(icone, color: CoresHortasmart.verde, size: 15),
            const SizedBox(width: 4),
            Expanded(
              child: Text(
                titulo,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: CoresHortasmart.textoSecundario,
                  fontSize: 10,
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
            color: CoresHortasmart.texto,
            fontSize: 13,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }
}

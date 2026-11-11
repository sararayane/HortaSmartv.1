import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:hortasmart/compartilhado/componentes/indicador_umidade.dart';

import '../../dados/modelos/canteiro.dart';
import '../../compartilhado/componentes/etiqueta_status.dart';
import '../../compartilhado/constantes/cores.dart';

class CartaoCanteiro extends StatelessWidget {
  const CartaoCanteiro({
    super.key,
    required this.canteiro,
    this.aoTocar,
    this.aoAlterarFoto,
  });

  final Canteiro canteiro;
  final VoidCallback? aoTocar;
  final VoidCallback? aoAlterarFoto;

  String get _emoji {
    switch (canteiro.cultura.trim().toLowerCase()) {
      case 'alface':
      case 'rúcula':
      case 'rucula':
      case 'couve':
        return '🥬';
      case 'tomate':
        return '🍅';
      case 'cenoura':
        return '🥕';
      case 'manjericão':
      case 'manjericao':
        return '🌿';
      default:
        return '🌱';
    }
  }

  Uint8List? _decodificarImagem() {
    final imagemBase64 = canteiro.imagemBase64;

    if (imagemBase64 == null || imagemBase64.isEmpty) {
      return null;
    }

    try {
      return base64Decode(imagemBase64);
    } on FormatException {
      // Uma imagem inválida não deve interromper a construção da tela.
      return null;
    }
  }

  Widget _construirEmoji({required double tamanho}) {
    return Container(
      alignment: Alignment.center,
      color: const Color(0xFFEAF5E9),
      child: Text(_emoji, style: TextStyle(fontSize: tamanho), maxLines: 1),
    );
  }

  Widget _construirImagem({
    required double largura,
    required double altura,
    required double tamanhoEmoji,
    required double tamanhoBotao,
  }) {
    final bytes = _decodificarImagem();

    return SizedBox(
      width: largura,
      height: altura,
      child: Stack(
        fit: StackFit.expand,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(15),
            child:
                bytes != null
                    ? Image.memory(
                      bytes,
                      fit: BoxFit.cover,
                      gaplessPlayback: true,
                      errorBuilder: (context, error, stackTrace) {
                        return _construirEmoji(tamanho: tamanhoEmoji);
                      },
                    )
                    : _construirEmoji(tamanho: tamanhoEmoji),
          ),
          if (aoAlterarFoto != null)
            Positioned(
              right: 4,
              bottom: 4,
              child: Material(
                color: Colors.white,
                shape: const CircleBorder(),
                elevation: 2,
                child: InkWell(
                  onTap: aoAlterarFoto,
                  customBorder: const CircleBorder(),
                  child: Padding(
                    padding: EdgeInsets.all(tamanhoBotao),
                    child: Icon(
                      Icons.camera_alt_rounded,
                      size: tamanhoBotao + 8,
                      color: CoresHortasmart.verde,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _construirRodape({required bool compacto}) {
    final corIrrigacao =
        canteiro.irrigando
            ? CoresHortasmart.azul
            : CoresHortasmart.textoSecundario;

    return Wrap(
      spacing: compacto ? 9 : 14,
      runSpacing: 5,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.flag_outlined,
              size: compacto ? 12 : 13,
              color: CoresHortasmart.textoSecundario,
            ),
            const SizedBox(width: 4),
            Text(
              'Meta ${canteiro.metaUmidade.round()}%',
              style: TextStyle(
                fontSize: compacto ? 9 : 10,
                color: CoresHortasmart.textoSecundario,
              ),
            ),
          ],
        ),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              canteiro.irrigando
                  ? Icons.water_drop_rounded
                  : Icons.pause_circle_outline_rounded,
              size: compacto ? 13 : 14,
              color: corIrrigacao,
            ),
            const SizedBox(width: 4),
            Text(
              canteiro.irrigando ? 'Irrigando' : 'Pausado',
              style: TextStyle(
                fontSize: compacto ? 9 : 10,
                fontWeight: FontWeight.w700,
                color: corIrrigacao,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _construirConteudo({required bool compacto}) {
    final estado = classificarUmidade(canteiro.umidadeAtual);
    final cultura =
        canteiro.cultura.trim().isNotEmpty
            ? canteiro.cultura.trim()
            : canteiro.nome;
    final identificador = canteiro.id.split('-').last.toUpperCase();

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                cultura,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: compacto ? 13 : 15,
                  color: CoresHortasmart.texto,
                ),
              ),
            ),
            const SizedBox(width: 2),
            Icon(
              Icons.chevron_right_rounded,
              color: Colors.grey.shade500,
              size: compacto ? 19 : 22,
            ),
          ],
        ),
        const SizedBox(height: 2),
        Text(
          identificador.isEmpty
              ? canteiro.nome
              : '${canteiro.nome} · Sensor $identificador',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: compacto ? 9 : 11,
            color: CoresHortasmart.textoSecundario,
          ),
        ),
        SizedBox(height: compacto ? 6 : 8),
        Wrap(
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: compacto ? 5 : 7,
          runSpacing: 4,
          children: [
            Text(
              '${canteiro.umidadeAtual.round()}%',
              style: TextStyle(
                fontSize: compacto ? 21 : 25,
                height: 1,
                fontWeight: FontWeight.w900,
                letterSpacing: -0.7,
                color: estado.cor,
              ),
            ),
            Text(
              'umidade',
              style: TextStyle(
                fontSize: compacto ? 9 : 10,
                color: CoresHortasmart.textoSecundario,
              ),
            ),
            EtiquetaStatus(
              texto: estado.texto,
              cor: estado.cor,
              fundo: estado.fundo,
            ),
          ],
        ),
        SizedBox(height: compacto ? 6 : 9),
        ClipRRect(
          borderRadius: BorderRadius.circular(99),
          child: LinearProgressIndicator(
            value: canteiro.umidadeAtual.clamp(0.0, 100.0) / 100.0,
            minHeight: compacto ? 5 : 6,
            backgroundColor: const Color(0xFFEAF0E9),
            valueColor: AlwaysStoppedAnimation<Color>(estado.cor),
          ),
        ),
        SizedBox(height: compacto ? 6 : 7),
        _construirRodape(compacto: compacto),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: aoTocar,
        child: Container(
          width: double.infinity,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: const Color(0xFFE5ECE6)),
          ),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final largura = constraints.maxWidth;
              final altura = constraints.maxHeight;
              final escalaTexto = MediaQuery.textScalerOf(context).scale(1);
              final compacto = largura < 330 || escalaTexto > 1.15;
              final muitoEstreito = largura < 205;

              // O layout vertical só é usado quando há altura suficiente.
              // Em cartões baixos, mantém imagem e informações lado a lado.
              final layoutVertical = muitoEstreito && altura >= 255;
              final padding = compacto ? 10.0 : 13.0;
              final tamanhoImagem =
                  muitoEstreito
                      ? 40.0
                      : compacto
                      ? 49.0
                      : 62.0;
              final alturaImagem =
                  muitoEstreito
                      ? 48.0
                      : compacto
                      ? 58.0
                      : 72.0;

              final imagem = _construirImagem(
                largura: tamanhoImagem,
                altura: alturaImagem,
                tamanhoEmoji: compacto ? 27 : 35,
                tamanhoBotao: compacto ? 3 : 4,
              );

              final conteudo = _construirConteudo(compacto: compacto);

              return Padding(
                padding: EdgeInsets.all(padding),
                child:
                    layoutVertical
                        ? Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Center(child: imagem),
                            const SizedBox(height: 9),
                            Expanded(
                              child: SingleChildScrollView(
                                physics: const ClampingScrollPhysics(),
                                child: conteudo,
                              ),
                            ),
                          ],
                        )
                        : Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            imagem,
                            SizedBox(width: compacto ? 9 : 13),
                            Expanded(child: conteudo),
                          ],
                        ),
              );
            },
          ),
        ),
      ),
    );
  }
}

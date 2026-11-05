import 'dart:convert';

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
    switch (canteiro.cultura.toLowerCase()) {
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

  Widget _construirImagem({
    required double largura,
    required double altura,
  }) {
    final imagemBase64 = canteiro.imagemBase64;

    final temImagem = imagemBase64 != null && imagemBase64.isNotEmpty;

    return SizedBox(
      width: largura,
      height: altura,
      child: Stack(
        children: [
          Positioned.fill(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(17),
              child: temImagem
                  ? Image.memory(
                      base64Decode(imagemBase64),
                      fit: BoxFit.cover,
                      gaplessPlayback: true,
                      errorBuilder: (context, error, stackTrace) {
                        return _construirEmoji();
                      },
                    )
                  : _construirEmoji(),
            ),
          ),
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
                child: const Padding(
                  padding: EdgeInsets.all(6),
                  child: Icon(
                    Icons.camera_alt_rounded,
                    size: 15,
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

  Widget _construirEmoji() {
    return Container(
      alignment: Alignment.center,
      color: const Color(0xFFEAF5E9),
      child: Text(
        _emoji,
        style: const TextStyle(fontSize: 35),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final estado = classificarUmidade(canteiro.umidadeAtual);

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: aoTocar,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: const Color(0xFFE5ECE6),
            ),
          ),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final estreito = constraints.maxWidth < 280;

              final imagem = _construirImagem(
                largura: estreito ? 48 : 61,
                altura: estreito ? 58 : 70,
              );

              final conteudo = Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            canteiro.cultura,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 15,
                              color: CoresHortasmart.texto,
                            ),
                          ),
                        ),
                        const Icon(
                          Icons.chevron_right_rounded,
                          color: Colors.grey,
                          size: 22,
                        ),
                      ],
                    ),
                    const SizedBox(height: 3),
                    Text(
                      '${canteiro.nome} · Sensor '
                      '${canteiro.id.split('-').last.toUpperCase()}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 11,
                        color: CoresHortasmart.textoSecundario,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      crossAxisAlignment: WrapCrossAlignment.center,
                      spacing: 7,
                      runSpacing: 5,
                      children: [
                        Text(
                          '${canteiro.umidadeAtual.round()}%',
                          style: TextStyle(
                            fontSize: 25,
                            height: 1,
                            fontWeight: FontWeight.w900,
                            letterSpacing: -0.7,
                            color: estado.cor,
                          ),
                        ),
                        const Text(
                          'umidade',
                          style: TextStyle(
                            fontSize: 10,
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
                    const SizedBox(height: 9),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(99),
                      child: LinearProgressIndicator(
                        value: canteiro.umidadeAtual.clamp(0, 100) / 100,
                        minHeight: 6,
                        backgroundColor: const Color(0xFFEAF0E9),
                        valueColor: AlwaysStoppedAnimation<Color>(
                          estado.cor,
                        ),
                      ),
                    ),
                    const SizedBox(height: 7),
                    Wrap(
                      alignment: WrapAlignment.spaceBetween,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      spacing: 8,
                      runSpacing: 5,
                      children: [
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.flag_outlined,
                              size: 13,
                              color: CoresHortasmart.textoSecundario,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'Meta ${canteiro.metaUmidade.round()}%',
                              style: const TextStyle(
                                fontSize: 10,
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
                              size: 14,
                              color: canteiro.irrigando
                                  ? CoresHortasmart.azul
                                  : CoresHortasmart.textoSecundario,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              canteiro.irrigando ? 'Irrigando' : 'Pausado',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: canteiro.irrigando
                                    ? CoresHortasmart.azul
                                    : CoresHortasmart.textoSecundario,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              );

              if (estreito) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    imagem,
                    const SizedBox(height: 10),
                    conteudo,
                  ],
                );
              }

              return Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  imagem,
                  const SizedBox(width: 13),
                  conteudo,
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

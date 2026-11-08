import 'dart:convert';

import 'package:http/http.dart' as http;

import '../modelos/previsao_tempo.dart';

class CidadeClima {
  final String nome;
  final String estado;
  final String pais;
  final double latitude;
  final double longitude;

  const CidadeClima({
    required this.nome,
    required this.estado,
    required this.pais,
    required this.latitude,
    required this.longitude,
  });

  String get descricao {
    final partes = <String>[
      if (estado.isNotEmpty) estado,
      if (pais.isNotEmpty) pais,
    ];

    return partes.join(', ');
  }
}

class ServicoClima {
  static const Duration _tempoLimite = Duration(seconds: 15);

  // Pesquisa várias cidades pelo nome.
  Future<List<CidadeClima>> buscarCidades(String nomeCidade) async {
    final cidade = nomeCidade.trim();

    if (cidade.length < 2) {
      return [];
    }

    final uri = Uri.https(
      'geocoding-api.open-meteo.com',
      '/v1/search',
      {
        'name': cidade,
        'count': '8',
        'language': 'pt',
        'format': 'json',
      },
    );

    final resposta = await http.get(uri).timeout(_tempoLimite);

    if (resposta.statusCode != 200) {
      throw Exception('Não foi possível pesquisar as cidades.');
    }

    final dados = jsonDecode(resposta.body) as Map<String, dynamic>;
    final resultados = dados['results'] as List<dynamic>?;

    if (resultados == null || resultados.isEmpty) {
      return [];
    }

    return resultados.map((item) {
      final local = item as Map<String, dynamic>;

      return CidadeClima(
        nome: local['name'] as String? ?? '',
        estado: local['admin1'] as String? ?? '',
        pais: local['country'] as String? ?? '',
        latitude: (local['latitude'] as num).toDouble(),
        longitude: (local['longitude'] as num).toDouble(),
      );
    }).toList();
  }

  // Consulta o clima da cidade selecionada.
  Future<PrevisaoTempo> buscarPorCidadeSelecionada(
    CidadeClima cidade,
  ) {
    return _buscarPrevisao(
      latitude: cidade.latitude,
      longitude: cidade.longitude,
      cidade: cidade.nome,
      pais: cidade.pais,
    );
  }

  // Mantido para compatibilidade com chamadas antigas.
  Future<PrevisaoTempo> buscarPorCidade(String nomeCidade) async {
    final cidade = nomeCidade.trim();

    if (cidade.isEmpty) {
      throw ArgumentError('Digite o nome de uma cidade.');
    }

    final resultados = await buscarCidades(cidade);

    if (resultados.isEmpty) {
      throw Exception(
        'Cidade não encontrada. Confira o nome e tente novamente.',
      );
    }

    return buscarPorCidadeSelecionada(resultados.first);
  }

  Future<PrevisaoTempo> buscarPorCoordenadas({
    required double latitude,
    required double longitude,
  }) async {
    var cidade = 'Minha localização';
    var pais = '';

    try {
      final uriLocal = Uri.https(
        'nominatim.openstreetmap.org',
        '/reverse',
        {
          'lat': latitude.toString(),
          'lon': longitude.toString(),
          'format': 'jsonv2',
          'accept-language': 'pt-BR',
          'zoom': '10',
        },
      );

      final respostaLocal = await http.get(
        uriLocal,
        headers: {
          'User-Agent': 'HortaSmart/1.0 (aplicativo meteorologico)',
        },
      ).timeout(_tempoLimite);

      if (respostaLocal.statusCode == 200) {
        final dadosLocal =
            jsonDecode(respostaLocal.body) as Map<String, dynamic>;

        final endereco = dadosLocal['address'] as Map<String, dynamic>?;

        if (endereco != null) {
          cidade = endereco['city'] as String? ??
              endereco['town'] as String? ??
              endereco['village'] as String? ??
              endereco['municipality'] as String? ??
              endereco['county'] as String? ??
              cidade;

          pais = endereco['country'] as String? ?? '';
        }
      }
    } catch (_) {
      // A previsão continua funcionando mesmo sem identificar a cidade.
    }

    return _buscarPrevisao(
      latitude: latitude,
      longitude: longitude,
      cidade: cidade,
      pais: pais,
    );
  }

  Future<PrevisaoTempo> _buscarPrevisao({
    required double latitude,
    required double longitude,
    required String cidade,
    required String pais,
  }) async {
    final uri = Uri.https(
      'api.open-meteo.com',
      '/v1/forecast',
      {
        'latitude': latitude.toString(),
        'longitude': longitude.toString(),
        'current':
            'temperature_2m,relative_humidity_2m,precipitation,weather_code,wind_speed_10m',
        'hourly': 'precipitation_probability',
        'forecast_days': '1',
        'timezone': 'auto',
      },
    );

    final resposta = await http.get(uri).timeout(_tempoLimite);

    if (resposta.statusCode != 200) {
      throw Exception('Não foi possível consultar a previsão do tempo.');
    }

    final dados = jsonDecode(resposta.body) as Map<String, dynamic>;
    final atual = dados['current'] as Map<String, dynamic>;

    final horario = DateTime.parse(atual['time'] as String);

    final dadosHorarios = dados['hourly'] as Map<String, dynamic>;
    final horarios = dadosHorarios['time'] as List<dynamic>;
    final probabilidades =
        dadosHorarios['precipitation_probability'] as List<dynamic>;

    final horarioAtual = (atual['time'] as String).substring(0, 13);

    final indiceHorario = horarios.indexWhere(
      (item) => (item as String).startsWith(horarioAtual),
    );

    double probabilidadeChuva = 0;

    if (indiceHorario >= 0 && indiceHorario < probabilidades.length) {
      final valor = probabilidades[indiceHorario];

      if (valor != null) {
        probabilidadeChuva = (valor as num).toDouble();
      }
    }

    return PrevisaoTempo(
      cidade: cidade,
      pais: pais,
      temperatura: (atual['temperature_2m'] as num).toDouble(),
      umidadeRelativa: (atual['relative_humidity_2m'] as num).toDouble(),
      probabilidadeChuva: probabilidadeChuva,
      velocidadeVento: (atual['wind_speed_10m'] as num).toDouble(),
      codigoClima: (atual['weather_code'] as num).toInt(),
      atualizadoEm: horario,
    );
  }
}

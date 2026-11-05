import 'dart:convert';

import 'package:http/http.dart' as http;

import '../modelos/previsao_tempo.dart';

class ServicoClima {
  static const Duration _tempoLimite = Duration(seconds: 15);

  Future<PrevisaoTempo> buscarPorCidade(String nomeCidade) async {
    final cidade = nomeCidade.trim();

    if (cidade.isEmpty) {
      throw ArgumentError('Digite o nome de uma cidade.');
    }

    final uri = Uri.https(
      'geocoding-api.open-meteo.com',
      '/v1/search',
      {
        'name': cidade,
        'count': '1',
        'language': 'pt',
        'format': 'json',
      },
    );

    final resposta = await http.get(uri).timeout(_tempoLimite);

    if (resposta.statusCode != 200) {
      throw Exception('Não foi possível localizar a cidade.');
    }

    final dados = jsonDecode(resposta.body) as Map<String, dynamic>;
    final resultados = dados['results'] as List<dynamic>?;

    if (resultados == null || resultados.isEmpty) {
      throw Exception(
        'Cidade não encontrada. Confira o nome e tente novamente.',
      );
    }

    final local = resultados.first as Map<String, dynamic>;

    return _buscarPrevisao(
      latitude: (local['latitude'] as num).toDouble(),
      longitude: (local['longitude'] as num).toDouble(),
      cidade: local['name'] as String? ?? cidade,
      pais: local['country'] as String? ?? '',
    );
  }

  Future<PrevisaoTempo> buscarPorCoordenadas({
    required double latitude,
    required double longitude,
  }) async {
    // A consulta meteorológica não depende de encontrar o nome da cidade.
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
      // Se o nome da cidade não puder ser identificado,
      // a consulta do clima ainda poderá continuar.
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

    var indiceHorario = horarios.indexWhere(
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

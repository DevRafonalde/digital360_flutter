import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../core/constants/api_constants.dart';

/// WEB SERVICE EXTERNO 1 (Parte 6): Open-Meteo.
/// Retorna o clima atual na regiao de entrega - dado relevante para a
/// AI Logistics (chuva/temperatura impactam risco e prazo de entrega).
/// API publica, gratuita e SEM necessidade de chave.
class WeatherService {
  Future<WeatherInfo> obterClima(double lat, double lon) async {
    final uri = Uri.parse(
      '${ApiConstants.openMeteoUrl}'
      '?latitude=$lat&longitude=$lon'
      '&current=temperature_2m,precipitation,weather_code,wind_speed_10m',
    );
    final res = await http.get(uri).timeout(const Duration(seconds: 8));
    if (res.statusCode == 200) {
      final j = jsonDecode(res.body);
      final c = j['current'] ?? {};
      return WeatherInfo(
        temperatura: (c['temperature_2m'] ?? 0).toDouble(),
        precipitacao: (c['precipitation'] ?? 0).toDouble(),
        ventoKmh: (c['wind_speed_10m'] ?? 0).toDouble(),
        codigo: c['weather_code'] ?? 0,
      );
    }
    throw Exception('Open-Meteo indisponivel (${res.statusCode})');
  }
}

class WeatherInfo {
  final double temperatura;
  final double precipitacao;
  final double ventoKmh;
  final int codigo;

  WeatherInfo({
    required this.temperatura,
    required this.precipitacao,
    required this.ventoKmh,
    required this.codigo,
  });

  String get descricao {
    if (precipitacao > 1) return 'Chuva — risco logístico elevado';
    if (ventoKmh > 40) return 'Vento forte';
    if (codigo == 0) return 'Céu limpo';
    if (codigo <= 3) return 'Parcialmente nublado';
    if (codigo >= 51) return 'Possibilidade de chuva';
    return 'Estável';
  }

  /// Fator de impacto do clima no risco de entrega (0-25).
  int get impactoRisco {
    int f = 0;
    if (precipitacao > 5) {
      f += 25;
    } else if (precipitacao > 1) {
      f += 12;
    }
    if (ventoKmh > 40) f += 8;
    return f > 25 ? 25 : f;
  }
}

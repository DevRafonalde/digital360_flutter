import 'package:geolocator/geolocator.dart';

/// Servico de geolocalizacao (Parte 5). Obtem a posicao atual do usuario
/// para centralizar o mapa e calcular proximidade de pontos relevantes.
class LocationService {
  Future<Position?> posicaoAtual() async {
    bool servicoAtivo = await Geolocator.isLocationServiceEnabled();
    if (!servicoAtivo) return null;

    LocationPermission permissao = await Geolocator.checkPermission();
    if (permissao == LocationPermission.denied) {
      permissao = await Geolocator.requestPermission();
      if (permissao == LocationPermission.denied) return null;
    }
    if (permissao == LocationPermission.deniedForever) return null;

    try {
      return await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(timeLimit: Duration(seconds: 8)),
      );
    } catch (_) {
      return null; // GPS lento/indisponivel - mapa segue funcionando sem a posicao do usuario
    }
  }
}

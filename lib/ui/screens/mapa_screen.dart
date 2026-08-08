import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart' as gmaps;
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart' as ll;
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../data/services/location_service.dart';
import '../../providers/auth_provider.dart';
import '../../providers/logistica_provider.dart';

/// Ponto neutro de mapa (nao amarrado a Google Maps nem a flutter_map),
/// usado para montar os marcadores uma unica vez e renderizar em qualquer
/// um dos dois motores de mapa abaixo.
class _PontoMapa {
  final String id;
  final double lat;
  final double lng;
  final String titulo;
  final String subtitulo;
  final Color cor;

  _PontoMapa({
    required this.id,
    required this.lat,
    required this.lng,
    required this.titulo,
    this.subtitulo = '',
    required this.cor,
  });
}

/// Tela de mapas e geolocalizacao (Parte 5).
/// Mostra: posicao do usuario + entregas monitoradas + lojas/centros de
/// distribuicao Leroy Merlin + polos de inclusao digital (telecentros).
///
/// Motor de mapa por plataforma:
/// - Mobile (Android/iOS): Google Maps (exige chave real - ver README).
/// - Web: OpenStreetMap via flutter_map, SEM necessidade de chave, para que
///   a demonstracao web funcione mesmo sem credenciais do Google Maps.
class MapaScreen extends StatefulWidget {
  const MapaScreen({super.key});

  @override
  State<MapaScreen> createState() => _MapaScreenState();
}

class _MapaScreenState extends State<MapaScreen> {
  final LocationService _location = LocationService();
  gmaps.GoogleMapController? _googleController;
  final MapController _osmController = MapController();

  static const _saoPauloLat = -23.5505;
  static const _saoPauloLng = -46.6333;

  List<_PontoMapa> _pontos = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _montarPontos());
  }

  Future<void> _montarPontos() async {
    final auth = context.read<AuthProvider>();
    final logistica = context.read<LogisticaProvider>();
    if (logistica.pedidos.isEmpty) {
      await logistica.carregar(auth.usuario?.bearer ?? '');
    }

    final pontos = <_PontoMapa>[];

    // 1) Entregas monitoradas (AI Logistics).
    for (final p in logistica.pedidos) {
      pontos.add(_PontoMapa(
        id: 'pedido_${p.id}',
        lat: p.latitude,
        lng: p.longitude,
        titulo: '${p.codigoPedido} - ${p.produto}',
        subtitulo: '${p.statusAtual} - ${p.regiaoEntrega}',
        cor: p.statusAtual == 'ATRASADO' ? Colors.redAccent : AppColors.primary,
      ));
    }

    // 2) Pontos fixos relevantes (lojas / telecentros / CD).
    final fixos = [
      ('Loja Leroy Merlin — Marginal Tietê', -23.5180, -46.6420, Colors.blueAccent),
      ('Centro de Distribuição LM', -23.5000, -46.5000, Colors.purpleAccent),
      ('Telecentro Inclusão Digital — Sé', -23.5500, -46.6340, AppColors.secondary),
      ('Telecentro - Itaquera', -23.5400, -46.4700, AppColors.secondary),
    ];
    for (var i = 0; i < fixos.length; i++) {
      final (titulo, lat, lng, cor) = fixos[i];
      pontos.add(_PontoMapa(id: 'ponto_$i', lat: lat, lng: lng, titulo: titulo, cor: cor));
    }

    // 3) Posicao atual do usuario (se permitido).
    final pos = await _location.posicaoAtual();
    if (pos != null) {
      pontos.add(_PontoMapa(
        id: 'usuario',
        lat: pos.latitude,
        lng: pos.longitude,
        titulo: 'Você está aqui',
        cor: Colors.cyanAccent,
      ));
      _googleController?.animateCamera(
        gmaps.CameraUpdate.newLatLng(gmaps.LatLng(pos.latitude, pos.longitude)),
      );
      _osmController.move(ll.LatLng(pos.latitude, pos.longitude), _osmController.camera.zoom);
    }

    if (mounted) setState(() => _pontos = pontos);
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        kIsWeb ? _buildMapaWeb() : _buildMapaGoogle(),
        Positioned(
          left: 12,
          right: 12,
          bottom: 12,
          child: Card(
            color: AppColors.surface.withValues(alpha: 0.95),
            child: const Padding(
              padding: EdgeInsets.all(12),
              child: Text(
                kIsWeb
                    ? 'Mapa web via OpenStreetMap (sem necessidade de chave). '
                        'Laranja: entregas • Vermelho: atraso • Azul: loja LM • '
                        'Roxo: CD • Verde: telecentro • Ciano: você'
                    : 'Laranja: entregas - Vermelho: atraso - Azul: loja LM - '
                        'Roxo: CD • Verde: telecentro • Ciano: você',
                style: TextStyle(fontSize: 12, color: AppColors.onSurface),
              ),
            ),
          ),
        ),
      ],
    );
  }

  /// Mobile (Android/iOS): Google Maps. Requer chave real em
  /// android/app/src/main/AndroidManifest.xml (ver README).
  Widget _buildMapaGoogle() {
    final markers = _pontos
        .map((p) => gmaps.Marker(
              markerId: gmaps.MarkerId(p.id),
              position: gmaps.LatLng(p.lat, p.lng),
              infoWindow: gmaps.InfoWindow(title: p.titulo, snippet: p.subtitulo),
            ))
        .toSet();

    return gmaps.GoogleMap(
      initialCameraPosition: const gmaps.CameraPosition(
        target: gmaps.LatLng(_saoPauloLat, _saoPauloLng),
        zoom: 11,
      ),
      markers: markers,
      myLocationEnabled: true,
      myLocationButtonEnabled: true,
      onMapCreated: (c) => _googleController = c,
    );
  }

  /// Web: OpenStreetMap via flutter_map - funciona sem nenhuma chave, para
  /// que a demonstracao web nao dependa de credenciais do Google Maps.
  Widget _buildMapaWeb() {
    return FlutterMap(
      mapController: _osmController,
      options: const MapOptions(
        initialCenter: ll.LatLng(_saoPauloLat, _saoPauloLng),
        initialZoom: 11,
      ),
      children: [
        TileLayer(
          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
          userAgentPackageName: 'br.com.fiap.digital360_flutter',
        ),
        MarkerLayer(
          markers: _pontos
              .map((p) => Marker(
                    point: ll.LatLng(p.lat, p.lng),
                    width: 36,
                    height: 36,
                    child: Tooltip(
                      message: '${p.titulo}\n${p.subtitulo}',
                      child: Icon(Icons.location_on, color: p.cor, size: 36),
                    ),
                  ))
              .toList(),
        ),
      ],
    );
  }
}

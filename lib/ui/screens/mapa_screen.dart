import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../data/services/location_service.dart';
import '../../providers/auth_provider.dart';
import '../../providers/logistica_provider.dart';

/// Tela de mapas e geolocalizacao (Parte 5).
/// Mostra: posicao do usuario + entregas monitoradas + lojas/centros de
/// distribuicao Leroy Merlin + polos de inclusao digital (telecentros).
class MapaScreen extends StatefulWidget {
  const MapaScreen({super.key});

  @override
  State<MapaScreen> createState() => _MapaScreenState();
}

class _MapaScreenState extends State<MapaScreen> {
  final LocationService _location = LocationService();
  GoogleMapController? _controller;
  final Set<Marker> _markers = {};

  static const _saoPaulo = LatLng(-23.5505, -46.6333);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _montarMarcadores());
  }

  Future<void> _montarMarcadores() async {
    final auth = context.read<AuthProvider>();
    final logistica = context.read<LogisticaProvider>();
    if (logistica.pedidos.isEmpty) {
      await logistica.carregar(auth.usuario?.bearer ?? '');
    }

    final markers = <Marker>{};

    // 1) Entregas monitoradas (AI Logistics).
    for (final p in logistica.pedidos) {
      markers.add(Marker(
        markerId: MarkerId('pedido_${p.id}'),
        position: LatLng(p.latitude, p.longitude),
        icon: BitmapDescriptor.defaultMarkerWithHue(
            p.statusAtual == 'ATRASADO'
                ? BitmapDescriptor.hueRed
                : BitmapDescriptor.hueOrange),
        infoWindow: InfoWindow(
            title: '${p.codigoPedido} - ${p.produto}',
            snippet: '${p.statusAtual} - ${p.regiaoEntrega}'),
      ));
    }

    // 2) Pontos fixos relevantes (lojas / telecentros).
    final pontos = [
      ['Loja Leroy Merlin — Marginal Tietê', -23.5180, -46.6420, BitmapDescriptor.hueAzure],
      ['Centro de Distribuição LM', -23.5000, -46.5000, BitmapDescriptor.hueViolet],
      ['Telecentro Inclusão Digital — Sé', -23.5500, -46.6340, BitmapDescriptor.hueGreen],
      ['Telecentro - Itaquera', -23.5400, -46.4700, BitmapDescriptor.hueGreen],
    ];
    for (var i = 0; i < pontos.length; i++) {
      final pt = pontos[i];
      markers.add(Marker(
        markerId: MarkerId('ponto_$i'),
        position: LatLng(pt[1] as double, pt[2] as double),
        icon: BitmapDescriptor.defaultMarkerWithHue(pt[3] as double),
        infoWindow: InfoWindow(title: pt[0] as String),
      ));
    }

    // 3) Posicao atual do usuario (se permitido).
    final pos = await _location.posicaoAtual();
    if (pos != null) {
      markers.add(Marker(
        markerId: const MarkerId('usuario'),
        position: LatLng(pos.latitude, pos.longitude),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueCyan),
        infoWindow: const InfoWindow(title: 'Você está aqui'),
      ));
      _controller?.animateCamera(
          CameraUpdate.newLatLng(LatLng(pos.latitude, pos.longitude)));
    }

    if (mounted) setState(() => _markers.addAll(markers));
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        GoogleMap(
          initialCameraPosition: const CameraPosition(target: _saoPaulo, zoom: 11),
          markers: _markers,
          myLocationEnabled: true,
          myLocationButtonEnabled: true,
          onMapCreated: (c) => _controller = c,
        ),
        Positioned(
          left: 12,
          right: 12,
          bottom: 12,
          child: Card(
            color: AppColors.surface.withOpacity(0.95),
            child: const Padding(
              padding: EdgeInsets.all(12),
              child: Text(
                'Laranja: entregas - Vermelho: atraso - Azul: loja LM - '
                'Roxo: CD • Verde: telecentro • Ciano: você',
                style: TextStyle(fontSize: 12, color: AppColors.onSurface),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

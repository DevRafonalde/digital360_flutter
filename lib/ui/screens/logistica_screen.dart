import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../providers/auth_provider.dart';
import '../../providers/logistica_provider.dart';
import '../widgets/risk_badge.dart';
import 'detalhe_entrega_screen.dart';
import '../widgets/offline_banner.dart';

/// Lista de pedidos monitorados pela AI Logistics Extension.
class LogisticaScreen extends StatefulWidget {
  const LogisticaScreen({super.key});

  @override
  State<LogisticaScreen> createState() => _LogisticaScreenState();
}

class _LogisticaScreenState extends State<LogisticaScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _carregar());
  }

  Future<void> _carregar() async {
    final auth = context.read<AuthProvider>();
    await context.read<LogisticaProvider>().carregar(auth.usuario?.bearer ?? '');
  }

  @override
  Widget build(BuildContext context) {
    final p = context.watch<LogisticaProvider>();
    if (p.carregando) {
      return const Center(child: CircularProgressIndicator(color: AppColors.primary));
    }
    return Column(
      children: [
        if (p.erro != null) const OfflineBanner(),
        Expanded(
          child: RefreshIndicator(
            onRefresh: _carregar,
            child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: p.pedidos.length,
        itemBuilder: (_, i) {
          final ped = p.pedidos[i];
          final risco = p.riscos[ped.id];
          return Card(
            child: InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: () => Navigator.push(context,
                  MaterialPageRoute(builder: (_) => DetalheEntregaScreen(pedido: ped))),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(ped.codigoPedido,
                            style: const TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 15)),
                        StatusChip(status: ped.statusAtual),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(ped.produto, style: const TextStyle(fontSize: 16)),
                    const SizedBox(height: 4),
                    Text('${ped.regiaoEntrega}  -  ${ped.distanciaKm} km',
                        style: const TextStyle(color: AppColors.onSurfaceMuted)),
                    const SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Prazo: ${ped.prazoPrometido}',
                            style: const TextStyle(color: AppColors.onSurface)),
                        if (risco != null)
                          RiskBadge(nivel: risco.riscoNivel, score: risco.riscoScore),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          );
        },
            ),
          ),
        ),
      ],
    );
  }
}

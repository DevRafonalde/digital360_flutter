import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';

/// Card compacto de estatística, usado no painel de gamificação e no painel
/// de impacto.
class StatCard extends StatelessWidget {
  final IconData icone;
  final String valor;
  final String rotulo;
  final Color? cor;

  const StatCard({
    super.key,
    required this.icone,
    required this.valor,
    required this.rotulo,
    this.cor,
  });

  @override
  Widget build(BuildContext context) {
    final corIcone = cor ?? AppColors.primary;
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 12),
        child: Column(
          children: [
            Icon(icone, color: corIcone, size: 28),
            const SizedBox(height: 10),
            Text(valor, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text(rotulo,
                textAlign: TextAlign.center,
                style: const TextStyle(color: AppColors.onSurfaceMuted, fontSize: 12)),
          ],
        ),
      ),
    );
  }
}

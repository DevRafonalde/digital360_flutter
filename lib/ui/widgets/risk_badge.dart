import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';

/// Chip de nivel de risco (AI Logistics) - semaforo de risco.
class RiskBadge extends StatelessWidget {
  final String nivel; // BAIXO | MEDIO | ALTO | CRITICO
  final int? score;
  const RiskBadge({super.key, required this.nivel, this.score});

  Color get _cor {
    switch (nivel.toUpperCase()) {
      case 'CRITICO':
        return AppColors.riskCritical;
      case 'ALTO':
        return AppColors.riskHigh;
      case 'MEDIO':
        return AppColors.riskMedium;
      default:
        return AppColors.riskLow;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: _cor.withOpacity(0.18),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _cor),
      ),
      child: Text(
        score != null ? 'RISCO $nivel - $score' : 'RISCO $nivel',
        style: TextStyle(color: _cor, fontWeight: FontWeight.bold, fontSize: 12),
      ),
    );
  }
}

/// Chip de status operacional do pedido.
class StatusChip extends StatelessWidget {
  final String status;
  const StatusChip({super.key, required this.status});

  Color get _cor {
    switch (status.toUpperCase()) {
      case 'ENTREGUE':
        return AppColors.statusDelivered;
      case 'EM_TRANSITO':
        return AppColors.statusInTransit;
      case 'ATRASADO':
        return AppColors.statusDelayed;
      default:
        return AppColors.statusPending;
    }
  }

  String get _label => status.replaceAll('_', ' ');

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: _cor.withOpacity(0.18),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(_label,
          style: TextStyle(color: _cor, fontWeight: FontWeight.w600, fontSize: 11)),
    );
  }
}

/// Badge de nivel do curso.
class NivelBadge extends StatelessWidget {
  final String nivel;
  const NivelBadge({super.key, required this.nivel});

  @override
  Widget build(BuildContext context) {
    Color cor;
    switch (nivel.toUpperCase()) {
      case 'AVANCADO':
        cor = AppColors.riskHigh;
        break;
      case 'INTERMEDIARIO':
        cor = AppColors.accent;
        break;
      default:
        cor = AppColors.secondary;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: cor.withOpacity(0.15),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(nivel,
          style: TextStyle(color: cor, fontWeight: FontWeight.w600, fontSize: 11)),
    );
  }
}

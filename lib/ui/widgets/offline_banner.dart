import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';

/// Banner exibido quando uma chamada de rede falha (ex.: sem conexao).
/// Reforca o principio de inclusao digital em cenarios de baixa conectividade:
/// o app continua util e avisa o usuario com clareza.
class OfflineBanner extends StatelessWidget {
  final String mensagem;
  const OfflineBanner({super.key, this.mensagem = 'Sem conexão — exibindo dados locais'});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: AppColors.statusPending.withValues(alpha: 0.15),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          const Icon(Icons.wifi_off, color: AppColors.statusPending, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(mensagem,
                style: const TextStyle(color: AppColors.statusPending, fontSize: 12)),
          ),
        ],
      ),
    );
  }
}

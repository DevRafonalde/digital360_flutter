import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';

/// Gancho pra video em Libras (Lingua Brasileira de Sinais) de um conteudo -
/// hoje mostra um estado "em breve", ainda NAO ha video real de interprete
/// gravado. A pasta `assets/libras/` ja fica preparada pra receber os
/// arquivos quando existirem, sem precisar mexer nesse widget de novo -
/// bastaria trocar o corpo por um VideoPlayer apontando pro asset.
class LibrasVideoPlaceholder extends StatelessWidget {
  final String? tituloConteudo;
  const LibrasVideoPlaceholder({super.key, this.tituloConteudo});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.outline),
      ),
      child: Row(
        children: [
          const Icon(Icons.sign_language_outlined, color: AppColors.onSurfaceMuted, size: 28),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Tradução em Libras', style: TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(height: 2),
                Text(
                  tituloConteudo != null
                      ? 'Em breve para "$tituloConteudo"'
                      : 'Em breve para este conteúdo',
                  style: const TextStyle(color: AppColors.onSurfaceMuted, fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

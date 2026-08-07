import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';

/// Estado vazio reutilizavel (sem cursos, sem pedidos, busca sem resultado)
/// - antes cada tela so mostrava uma lista em branco ou um Text solto.
class EmptyState extends StatelessWidget {
  final IconData icone;
  final String titulo;
  final String? subtitulo;

  const EmptyState({super.key, required this.icone, required this.titulo, this.subtitulo});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icone, size: 56, color: AppColors.onSurfaceMuted),
            const SizedBox(height: 16),
            Text(titulo,
                textAlign: TextAlign.center,
                style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
            if (subtitulo != null) ...[
              const SizedBox(height: 8),
              Text(subtitulo!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: AppColors.onSurfaceMuted)),
            ],
          ],
        ),
      ),
    );
  }
}

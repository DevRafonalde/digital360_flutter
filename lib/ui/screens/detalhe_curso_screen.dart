import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../data/models/curso.dart';
import '../widgets/risk_badge.dart';

class DetalheCursoScreen extends StatelessWidget {
  final Curso curso;
  const DetalheCursoScreen({super.key, required this.curso});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Detalhes do curso')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          NivelBadge(nivel: curso.nivel),
          const SizedBox(height: 12),
          Text(curso.titulo,
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          Text(curso.descricao, style: const TextStyle(color: AppColors.onSurface)),
          const SizedBox(height: 24),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  _linha('Carga horária', '${curso.cargaHoraria} horas'),
                  _linha('Modulos', '${curso.totalModulos}'),
                  _linha('Progresso', '${curso.progresso}%'),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          LinearProgressIndicator(
            value: curso.progresso / 100,
            backgroundColor: AppColors.surfaceVariant,
            color: AppColors.secondary,
            minHeight: 10,
            borderRadius: BorderRadius.circular(6),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () {},
            icon: const Icon(Icons.play_arrow),
            label: Text(curso.progresso > 0 ? 'Continuar curso' : 'Começar curso'),
          ),
        ],
      ),
    );
  }

  Widget _linha(String k, String v) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(k, style: const TextStyle(color: AppColors.onSurfaceMuted)),
            Text(v, style: const TextStyle(fontWeight: FontWeight.w600)),
          ],
        ),
      );
}

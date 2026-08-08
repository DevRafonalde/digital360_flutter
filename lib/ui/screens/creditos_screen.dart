import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';

class CreditosScreen extends StatelessWidget {
  const CreditosScreen({super.key});

  static const _integrantes = [
    ['Eduardo Andrade Martins Vasques', 'RM 556970'],
    ['Otávio Ramos dos Santos Souza', 'RM 550361'],
    ['Enzo Miranda Ward de Paiva', 'RM 557632'],
    ['Rafael Pinto de Albuquerque', 'RM 559136'],
    ['Guilherme Leoni Vidigal Tiburcio', 'RM 557500'],
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Créditos')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const Text('Desenvolvido por',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          ..._integrantes.map((m) => Card(
                child: ListTile(
                  leading: const CircleAvatar(
                    backgroundColor: AppColors.surfaceVariant,
                    child: Icon(Icons.person, color: AppColors.primary),
                  ),
                  title: Text(m[0]),
                  subtitle: Text(m[1]),
                ),
              )),
          const SizedBox(height: 16),
          const Text(
            'Projeto Anual — Sociedade 5.0\n'
            'Smart HAS / Digital 360 — AI Logistics Extension\n'
            'FIAP — Faculdade de Informática e Administração Paulista\n'
            'Ano: 2026',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.onSurfaceMuted, height: 1.5),
          ),
          const SizedBox(height: 16),
          const Text('v1.1.0',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.onSurfaceMuted, fontSize: 12)),
        ],
      ),
    );
  }
}

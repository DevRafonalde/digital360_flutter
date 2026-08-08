import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../data/models/servico.dart';
import '../../data/services/tts_service.dart';

class DetalheServicoScreen extends StatefulWidget {
  final Servico servico;
  const DetalheServicoScreen({super.key, required this.servico});

  @override
  State<DetalheServicoScreen> createState() => _DetalheServicoScreenState();
}

class _DetalheServicoScreenState extends State<DetalheServicoScreen> {
  @override
  void dispose() {
    TtsService.instance.parar();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final servico = widget.servico;
    return Scaffold(
      appBar: AppBar(
        title: Text(servico.orgao),
        actions: [
          IconButton(
            tooltip: 'Ouvir',
            icon: const Icon(Icons.volume_up_outlined),
            onPressed: () => TtsService.instance
                .falar('${servico.titulo}. ${servico.descricao}. ${servico.conteudo}'),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text(servico.titulo,
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text('${servico.categoria}  -  ${servico.orgao}',
              style: const TextStyle(color: AppColors.onSurfaceMuted)),
          const SizedBox(height: 20),
          Text(servico.descricao,
              style: const TextStyle(fontSize: 16, color: AppColors.onSurface)),
          const SizedBox(height: 20),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Como fazer',
                      style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.secondary)),
                  const SizedBox(height: 8),
                  Text(servico.conteudo, style: const TextStyle(height: 1.5)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../data/services/mock_data.dart';
import '../../data/services/tts_service.dart';

/// Tela de leitura de um modulo de curso - conteudo real (nao so um titulo),
/// com botao "Ouvir" (TTS) e "Concluir modulo" que soma um passo de progresso
/// via CursosProvider.avancar() (chamado pela tela anterior apos o retorno).
class LicaoModuloScreen extends StatelessWidget {
  final int cursoId;
  final String titulo;
  final int indice;
  final int totalModulos;
  final bool jaConcluido;
  final VoidCallback onConcluir;

  const LicaoModuloScreen({
    super.key,
    required this.cursoId,
    required this.titulo,
    required this.indice,
    required this.totalModulos,
    required this.jaConcluido,
    required this.onConcluir,
  });

  @override
  Widget build(BuildContext context) {
    final conteudo = MockData.conteudoModulo(cursoId, titulo);

    return Scaffold(
      appBar: AppBar(
        title: Text('Módulo ${indice + 1} de $totalModulos'),
        actions: [
          IconButton(
            tooltip: 'Ouvir',
            icon: const Icon(Icons.volume_up_outlined),
            onPressed: () => TtsService.instance.falar('$titulo. $conteudo'),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text(titulo, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          Text(
            conteudo,
            style: const TextStyle(fontSize: 16, height: 1.6, color: AppColors.onSurface),
          ),
          const SizedBox(height: 32),
          if (jaConcluido)
            Container(
              padding: const EdgeInsets.symmetric(vertical: 14),
              decoration: BoxDecoration(
                color: AppColors.secondary.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.check_circle, color: AppColors.secondary),
                  SizedBox(width: 8),
                  Text('Módulo já concluído', style: TextStyle(fontWeight: FontWeight.w600)),
                ],
              ),
            )
          else
            ElevatedButton.icon(
              onPressed: () {
                onConcluir();
                Navigator.pop(context);
              },
              icon: const Icon(Icons.check),
              label: const Text('Concluir módulo'),
            ),
        ],
      ),
    );
  }
}

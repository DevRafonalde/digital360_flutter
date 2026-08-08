import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../providers/auth_provider.dart';
import '../../providers/forum_provider.dart';
import '../widgets/empty_state.dart';

/// Detalhe de uma pergunta do fórum: corpo, lista de respostas e campo para
/// responder.
class DetalhePerguntaScreen extends StatefulWidget {
  final int perguntaId;
  const DetalhePerguntaScreen({super.key, required this.perguntaId});

  @override
  State<DetalhePerguntaScreen> createState() => _DetalhePerguntaScreenState();
}

class _DetalhePerguntaScreenState extends State<DetalhePerguntaScreen> {
  final _resposta = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _carregar());
  }

  @override
  void dispose() {
    _resposta.dispose();
    super.dispose();
  }

  Future<void> _carregar() async {
    final auth = context.read<AuthProvider>();
    await context.read<ForumProvider>().carregarDetalhe(auth.usuario?.bearer ?? '', widget.perguntaId);
  }

  Future<void> _enviar() async {
    if (_resposta.text.trim().isEmpty) return;
    final auth = context.read<AuthProvider>();
    final provider = context.read<ForumProvider>();
    final ok = await provider.responder(
      auth.usuario?.bearer ?? '',
      widget.perguntaId,
      auth.usuario?.nomeAmigavel ?? 'Visitante',
      _resposta.text.trim(),
    );
    if (!mounted) return;
    if (ok) {
      _resposta.clear();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(provider.erro ?? 'Não foi possível enviar agora.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = context.watch<ForumProvider>();
    final pergunta = p.perguntaAtual;
    return Scaffold(
      appBar: AppBar(title: const Text('Pergunta')),
      body: p.carregando && pergunta == null
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : pergunta == null
              ? const EmptyState(
                  icone: Icons.help_outline,
                  titulo: 'Pergunta não encontrada',
                  subtitulo: 'Ela pode ter sido removida',
                )
              : Column(
                  children: [
                    Expanded(
                      child: ListView(
                        padding: const EdgeInsets.all(16),
                        children: [
                          Text(pergunta.titulo,
                              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 6),
                          Text('por ${pergunta.autorNome}',
                              style: const TextStyle(color: AppColors.onSurfaceMuted, fontSize: 12)),
                          const SizedBox(height: 12),
                          Text(pergunta.corpo, style: const TextStyle(color: AppColors.onSurface)),
                          const SizedBox(height: 24),
                          Text('${pergunta.totalRespostas} respostas',
                              style: const TextStyle(fontWeight: FontWeight.bold)),
                          const SizedBox(height: 8),
                          for (final r in pergunta.respostas)
                            Card(
                              child: Padding(
                                padding: const EdgeInsets.all(14),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(r.autorNome,
                                        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                                    const SizedBox(height: 4),
                                    Text(r.corpo),
                                  ],
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                    SafeArea(
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: _resposta,
                                decoration: const InputDecoration(hintText: 'Escreva uma resposta...'),
                                minLines: 1,
                                maxLines: 4,
                              ),
                            ),
                            const SizedBox(width: 8),
                            IconButton.filled(
                              onPressed: p.enviando ? null : _enviar,
                              icon: const Icon(Icons.send),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
    );
  }
}

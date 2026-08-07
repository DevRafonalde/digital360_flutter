import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../providers/auth_provider.dart';
import '../../providers/forum_provider.dart';
import '../widgets/empty_state.dart';
import '../widgets/offline_banner.dart';
import 'detalhe_pergunta_screen.dart';

/// Fórum de perguntas e respostas da comunidade.
class ForumScreen extends StatefulWidget {
  const ForumScreen({super.key});

  @override
  State<ForumScreen> createState() => _ForumScreenState();
}

class _ForumScreenState extends State<ForumScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _carregar());
  }

  Future<void> _carregar() async {
    final auth = context.read<AuthProvider>();
    await context.read<ForumProvider>().carregarPerguntas(auth.usuario?.bearer ?? '');
  }

  Future<void> _novaPergunta() async {
    final tituloCtrl = TextEditingController();
    final corpoCtrl = TextEditingController();
    final enviar = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Nova pergunta'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: tituloCtrl, decoration: const InputDecoration(labelText: 'Título')),
            const SizedBox(height: 12),
            TextField(
              controller: corpoCtrl,
              decoration: const InputDecoration(labelText: 'Detalhe sua dúvida'),
              minLines: 2,
              maxLines: 4,
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
          ElevatedButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Publicar')),
        ],
      ),
    );
    if (enviar != true || !mounted) return;
    if (tituloCtrl.text.trim().isEmpty || corpoCtrl.text.trim().isEmpty) return;

    final auth = context.read<AuthProvider>();
    final provider = context.read<ForumProvider>();
    final ok = await provider.criarPergunta(
      auth.usuario?.bearer ?? '',
      auth.usuario?.nomeAmigavel ?? 'Visitante',
      tituloCtrl.text.trim(),
      corpoCtrl.text.trim(),
    );
    if (!mounted) return;
    if (!ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(provider.erro ?? 'Não foi possível publicar agora.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = context.watch<ForumProvider>();
    return Scaffold(
      appBar: AppBar(title: const Text('Fórum da comunidade')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _novaPergunta,
        icon: const Icon(Icons.add),
        label: const Text('Perguntar'),
      ),
      body: p.carregando
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : Column(
              children: [
                if (p.erro != null) OfflineBanner(mensagem: p.erro!),
                Expanded(
                  child: p.perguntas.isEmpty
                      ? const EmptyState(
                          icone: Icons.forum_outlined,
                          titulo: 'Nenhuma pergunta ainda',
                          subtitulo: 'Seja o primeiro a perguntar algo para a comunidade',
                        )
                      : RefreshIndicator(
                          onRefresh: _carregar,
                          child: ListView.builder(
                            padding: const EdgeInsets.all(16),
                            itemCount: p.perguntas.length,
                            itemBuilder: (_, i) {
                              final pergunta = p.perguntas[i];
                              return Card(
                                child: ListTile(
                                  title: Text(pergunta.titulo,
                                      style: const TextStyle(fontWeight: FontWeight.w600)),
                                  subtitle: Text('por ${pergunta.autorNome}'),
                                  trailing: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(Icons.chat_bubble_outline,
                                          size: 16, color: AppColors.onSurfaceMuted),
                                      const SizedBox(width: 4),
                                      Text('${pergunta.totalRespostas}'),
                                    ],
                                  ),
                                  onTap: () => Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => DetalhePerguntaScreen(perguntaId: pergunta.id),
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                ),
              ],
            ),
    );
  }
}

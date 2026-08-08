import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../providers/auth_provider.dart';
import '../../providers/cursos_provider.dart';
import '../../providers/recomendacoes_provider.dart';
import '../../providers/servicos_provider.dart';
import '../widgets/empty_state.dart';
import 'detalhe_curso_screen.dart';
import 'detalhe_servico_screen.dart';

/// Vitrine do motor de recomendacao (GET /recomendacoes/{userId}) - a
/// funcionalidade mais citada na documentacao da AI Logistics Extension,
/// que ate esta correcao nao tinha nenhuma tela no app.
class RecomendacoesScreen extends StatefulWidget {
  const RecomendacoesScreen({super.key});

  @override
  State<RecomendacoesScreen> createState() => _RecomendacoesScreenState();
}

class _RecomendacoesScreenState extends State<RecomendacoesScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _carregar());
  }

  Future<void> _carregar() async {
    final auth = context.read<AuthProvider>();
    final recomendacoes = context.read<RecomendacoesProvider>();
    await recomendacoes.carregar(auth.usuario?.bearer ?? '', auth.usuario?.nomeUser ?? 'visitante');
  }

  void _abrir(Map<String, dynamic> item) {
    final tipo = item['tipo'];
    final id = item['id'] as int;
    if (tipo == 'curso') {
      final curso = context.read<CursosProvider>().cursos.where((c) => c.id == id);
      if (curso.isNotEmpty) {
        Navigator.push(
            context, MaterialPageRoute(builder: (_) => DetalheCursoScreen(curso: curso.first)));
      }
    } else if (tipo == 'servico') {
      final servico = context.read<ServicosProvider>().servicos.where((s) => s.id == id);
      if (servico.isNotEmpty) {
        Navigator.push(context,
            MaterialPageRoute(builder: (_) => DetalheServicoScreen(servico: servico.first)));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final r = context.watch<RecomendacoesProvider>();
    return Scaffold(
      appBar: AppBar(title: const Text('Recomendado para você')),
      body: RefreshIndicator(
        onRefresh: _carregar,
        child: r.carregando
            ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
            : r.erro != null
                ? ListView(children: [
                    const SizedBox(height: 120),
                    Center(child: Text(r.erro!)),
                    Center(child: TextButton(onPressed: _carregar, child: const Text('Tentar de novo'))),
                  ])
                : r.itens.isEmpty
                    ? const EmptyState(
                        icone: Icons.auto_awesome_outlined,
                        titulo: 'Ainda sem recomendações',
                        subtitulo: 'Explore cursos e serviços para receber sugestões personalizadas',
                      )
                    : ListView(
                        padding: const EdgeInsets.all(16),
                        children: [
                          const Text(
                            'Sugestões calculadas pelo motor de recomendação da AI Logistics '
                            'Extension, com base no seu uso do app.',
                            style: TextStyle(color: AppColors.onSurfaceMuted),
                          ),
                          const SizedBox(height: 16),
                          ...r.itens.map(_card),
                        ],
                      ),
      ),
    );
  }

  Widget _card(Map<String, dynamic> item) {
    final ehCurso = item['tipo'] == 'curso';
    final coldStart = item['motivo'] == 'cold-start';
    return Card(
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: (ehCurso ? AppColors.secondary : AppColors.accent).withValues(alpha: 0.15),
          child: Icon(ehCurso ? Icons.school_outlined : Icons.account_balance,
              color: ehCurso ? AppColors.secondary : AppColors.accent),
        ),
        title: Text(item['titulo']?.toString() ?? '',
            style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text(ehCurso
            ? 'Curso • nível ${item['nivel']}'
            : 'Serviço • ${item['categoria']}'),
        trailing: coldStart
            ? null
            : Chip(
                label: Text('score ${item['score']}', style: const TextStyle(fontSize: 11)),
                backgroundColor: AppColors.surfaceVariant,
              ),
        onTap: () => _abrir(item),
      ),
    );
  }
}

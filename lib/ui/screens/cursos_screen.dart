import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../providers/auth_provider.dart';
import '../../providers/cursos_provider.dart';
import '../../providers/recomendacoes_provider.dart';
import '../widgets/risk_badge.dart';
import 'criar_curso_screen.dart';
import 'detalhe_curso_screen.dart';
import '../widgets/offline_banner.dart';
import '../widgets/empty_state.dart';

class CursosScreen extends StatefulWidget {
  const CursosScreen({super.key});

  @override
  State<CursosScreen> createState() => _CursosScreenState();
}

class _CursosScreenState extends State<CursosScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _carregar());
  }

  Future<void> _carregar() async {
    final auth = context.read<AuthProvider>();
    await context.read<CursosProvider>().carregar(auth.usuario?.bearer ?? '');
  }

  Future<void> _criarCurso() async {
    final criado = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => const CriarCursoScreen()),
    );
    if (criado == true) _carregar();
  }

  @override
  Widget build(BuildContext context) {
    final p = context.watch<CursosProvider>();
    final isTutor = context.watch<AuthProvider>().usuario?.isTutor ?? false;
    if (p.carregando) {
      return const Center(child: CircularProgressIndicator(color: AppColors.primary));
    }
    if (p.erro != null && p.cursos.isEmpty) {
      return _erro(p.erro!);
    }
    return Scaffold(
      floatingActionButton: isTutor
          ? FloatingActionButton.extended(
              onPressed: _criarCurso,
              icon: const Icon(Icons.add),
              label: const Text('Criar curso'),
            )
          : null,
      body: Column(
        children: [
          if (p.erro != null) OfflineBanner(mensagem: p.erro!),
          Expanded(
            child: p.cursos.isEmpty
                ? const EmptyState(
                    icone: Icons.school_outlined,
                    titulo: 'Nenhum curso disponível ainda',
                    subtitulo: 'Puxe para atualizar ou volte mais tarde',
                  )
                : RefreshIndicator(
                    onRefresh: _carregar,
                    child: ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: p.cursos.length,
                      itemBuilder: (_, i) {
                        final c = p.cursos[i];
                        return Card(
                          child: InkWell(
                            borderRadius: BorderRadius.circular(16),
                            onTap: () {
                              final auth = context.read<AuthProvider>();
                              context.read<RecomendacoesProvider>().registrarVisita(
                                    auth.usuario?.bearer ?? '',
                                    userId: auth.usuario?.nomeUser ?? 'visitante',
                                    tipo: 'curso',
                                    referenceId: c.id,
                                  );
                              Navigator.push(context,
                                  MaterialPageRoute(builder: (_) => DetalheCursoScreen(curso: c)));
                            },
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Expanded(
                                        child: Text(c.titulo,
                                            style: const TextStyle(
                                                fontWeight: FontWeight.bold, fontSize: 16)),
                                      ),
                                      Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          if (c.isComunidade) ...[
                                            const ComunidadeBadge(),
                                            const SizedBox(width: 6),
                                          ],
                                          NivelBadge(nivel: c.nivel),
                                        ],
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 6),
                                  Text(c.descricao,
                                      style: const TextStyle(color: AppColors.onSurface)),
                                  const SizedBox(height: 12),
                                  LinearProgressIndicator(
                                    value: c.progresso / 100,
                                    backgroundColor: AppColors.surfaceVariant,
                                    color: AppColors.primary,
                                    minHeight: 8,
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                      '${c.progresso}% concluído  •  ${c.totalModulos} módulos  •  ${c.cargaHoraria}h',
                                      style: const TextStyle(
                                          color: AppColors.onSurfaceMuted, fontSize: 12)),
                                ],
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

  Widget _erro(String msg) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.cloud_off, color: AppColors.onSurfaceMuted, size: 48),
            const SizedBox(height: 12),
            Text(msg, textAlign: TextAlign.center),
            const SizedBox(height: 12),
            ElevatedButton(onPressed: _carregar, child: const Text('Tentar novamente')),
          ],
        ),
      );
}

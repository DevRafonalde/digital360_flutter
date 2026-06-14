import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../providers/auth_provider.dart';
import '../../providers/cursos_provider.dart';
import '../widgets/risk_badge.dart';
import 'detalhe_curso_screen.dart';
import '../widgets/offline_banner.dart';

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

  @override
  Widget build(BuildContext context) {
    final p = context.watch<CursosProvider>();
    if (p.carregando) {
      return const Center(child: CircularProgressIndicator(color: AppColors.primary));
    }
    if (p.erro != null && p.cursos.isEmpty) {
      return _erro(p.erro!);
    }
    return Column(
      children: [
        if (p.erro != null) const OfflineBanner(),
        Expanded(
          child: RefreshIndicator(
      onRefresh: _carregar,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: p.cursos.length,
        itemBuilder: (_, i) {
          final c = p.cursos[i];
          return Card(
            child: InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: () => Navigator.push(context,
                  MaterialPageRoute(builder: (_) => DetalheCursoScreen(curso: c))),
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
                        NivelBadge(nivel: c.nivel),
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

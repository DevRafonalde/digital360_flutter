import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../data/services/api_service.dart';
import '../../providers/auth_provider.dart';
import '../widgets/stat_card.dart';

/// Painel de impacto (conceito de "painel municipal"): números agregados da
/// base de dados atual. Rotulado honestamente como dados da demonstração,
/// não uma alegação de escala real.
class ImpactoScreen extends StatefulWidget {
  const ImpactoScreen({super.key});

  @override
  State<ImpactoScreen> createState() => _ImpactoScreenState();
}

class _ImpactoScreenState extends State<ImpactoScreen> {
  bool _carregando = true;
  String? _erro;
  Map<String, dynamic>? _metricas;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _carregar());
  }

  Future<void> _carregar() async {
    setState(() {
      _carregando = true;
      _erro = null;
    });
    try {
      final auth = context.read<AuthProvider>();
      final metricas = await ApiService.instance.getMetricasImpacto(auth.usuario?.bearer ?? '');
      if (!mounted) return;
      setState(() => _metricas = metricas);
    } catch (_) {
      if (!mounted) return;
      setState(() => _erro = 'Não foi possível carregar as métricas agora.');
    } finally {
      if (mounted) setState(() => _carregando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Painel de impacto')),
      body: _carregando
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : _erro != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.cloud_off, color: AppColors.onSurfaceMuted, size: 48),
                      const SizedBox(height: 12),
                      Text(_erro!, textAlign: TextAlign.center),
                      const SizedBox(height: 12),
                      ElevatedButton(onPressed: _carregar, child: const Text('Tentar novamente')),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _carregar,
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      const Text('Painel Municipal (conceito)',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                      const SizedBox(height: 4),
                      Text(_metricas?['observacao']?.toString() ?? '',
                          style: const TextStyle(color: AppColors.onSurfaceMuted, fontSize: 12)),
                      const SizedBox(height: 20),
                      GridView.count(
                        crossAxisCount: 2,
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        mainAxisSpacing: 12,
                        crossAxisSpacing: 12,
                        childAspectRatio: 1.3,
                        children: [
                          StatCard(
                            icone: Icons.people_outline,
                            valor: '${_metricas?['totalUsuarios'] ?? 0}',
                            rotulo: 'Usuários cadastrados',
                          ),
                          StatCard(
                            icone: Icons.emoji_events_outlined,
                            valor: '${_metricas?['totalCursosConcluidos'] ?? 0}',
                            rotulo: 'Cursos concluídos',
                            cor: AppColors.riskHigh,
                          ),
                          StatCard(
                            icone: Icons.school_outlined,
                            valor: '${_metricas?['totalCursosPublicados'] ?? 0}',
                            rotulo: 'Cursos publicados',
                            cor: AppColors.statusInTransit,
                          ),
                          StatCard(
                            icone: Icons.groups_outlined,
                            valor: '${_metricas?['totalCursosComunidade'] ?? 0}',
                            rotulo: 'Criados pela comunidade',
                            cor: AppColors.statusInTransit,
                          ),
                          StatCard(
                            icone: Icons.forum_outlined,
                            valor: '${_metricas?['totalPerguntasForum'] ?? 0}',
                            rotulo: 'Perguntas no fórum',
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../providers/auth_provider.dart';
import '../../providers/gamificacao_provider.dart';
import '../widgets/stat_card.dart';

/// Painel de gamificação: cursos concluídos, sequência de dias, pontos e
/// ranking (top 10) - calculado a partir dos eventos de uso já registrados.
class ConquistasScreen extends StatefulWidget {
  const ConquistasScreen({super.key});

  @override
  State<ConquistasScreen> createState() => _ConquistasScreenState();
}

class _ConquistasScreenState extends State<ConquistasScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _carregar());
  }

  Future<void> _carregar() async {
    final auth = context.read<AuthProvider>();
    final bearer = auth.usuario?.bearer ?? '';
    final userId = auth.usuario?.nomeUser ?? 'visitante';
    final provider = context.read<GamificacaoProvider>();
    await provider.carregarResumo(bearer, userId);
    await provider.carregarRanking(bearer);
  }

  @override
  Widget build(BuildContext context) {
    final p = context.watch<GamificacaoProvider>();
    return Scaffold(
      appBar: AppBar(title: const Text('Minhas conquistas')),
      body: p.carregando
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : RefreshIndicator(
              onRefresh: _carregar,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: StatCard(
                          icone: Icons.emoji_events_outlined,
                          valor: '${p.cursosConcluidos}',
                          rotulo: 'Cursos concluídos',
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: StatCard(
                          icone: Icons.local_fire_department_outlined,
                          valor: '${p.sequenciaDias}',
                          rotulo: 'Dias seguidos',
                          cor: AppColors.riskHigh,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: StatCard(
                          icone: Icons.star_outline,
                          valor: '${p.pontos}',
                          rotulo: 'Pontos',
                          cor: AppColors.statusInTransit,
                        ),
                      ),
                    ],
                  ),
                  if (p.cursosConcluidos >= 3) ...[
                    const SizedBox(height: 24),
                    Card(
                      color: AppColors.primary.withValues(alpha: 0.1),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          children: [
                            const Icon(Icons.redeem_outlined, color: AppColors.primary, size: 32),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text('Você desbloqueou um cupom!',
                                      style: TextStyle(fontWeight: FontWeight.bold)),
                                  const SizedBox(height: 4),
                                  const Text(
                                    '10% de desconto em uma loja Leroy Merlin — código DIGITAL360-10',
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Recompensa simbólica de demonstração (não integra com resgate real).',
                                    style: TextStyle(
                                        fontSize: 11,
                                        color: AppColors.onSurfaceMuted.withValues(alpha: 0.8)),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 24),
                  const Text('Ranking da comunidade',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(height: 12),
                  if (p.ranking.isEmpty)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 12),
                      child: Text('Ninguém pontuou ainda. Conclua um curso para aparecer aqui!',
                          style: TextStyle(color: AppColors.onSurfaceMuted)),
                    )
                  else
                    for (int i = 0; i < p.ranking.length; i++)
                      Card(
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: AppColors.primary.withValues(alpha: 0.15),
                            child: Text('${i + 1}º',
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                          ),
                          title: Text(p.ranking[i]['nomeAmigavel']?.toString() ?? '—'),
                          trailing: Text('${p.ranking[i]['pontos']} pts',
                              style: const TextStyle(fontWeight: FontWeight.w600)),
                        ),
                      ),
                ],
              ),
            ),
    );
  }
}

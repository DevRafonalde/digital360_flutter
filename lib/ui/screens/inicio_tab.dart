import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../providers/auth_provider.dart';
import '../../providers/cursos_provider.dart';
import '../../data/services/notification_service.dart';
import 'assistente_screen.dart';
import 'conquistas_screen.dart';
import 'forum_screen.dart';
import 'impacto_screen.dart';
import 'tendencias_screen.dart';
import 'recomendacoes_screen.dart';

/// Tela inicial: painel de jornada do usuario (rastreabilidade da AI Logistics)
/// + atalhos. Equivale ao HomeFragment do Kotlin.
class InicioTab extends StatefulWidget {
  const InicioTab({super.key});

  @override
  State<InicioTab> createState() => _InicioTabState();
}

class _InicioTabState extends State<InicioTab> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final auth = context.read<AuthProvider>();
      context.read<CursosProvider>().carregar(auth.usuario?.bearer ?? '');
    });
  }

  @override
  Widget build(BuildContext context) {
    final cursos = context.watch<CursosProvider>();
    final emAndamento = cursos.cursos.where((c) => c.progresso > 0 && c.progresso < 100).toList();
    final progressoMedio = cursos.cursos.isEmpty
        ? 0
        : cursos.cursos.map((c) => c.progresso).reduce((a, b) => a + b) ~/
            cursos.cursos.length;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Painel de jornada
        Card(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.route, color: AppColors.secondary),
                    SizedBox(width: 8),
                    Text('Sua jornada de inclusão digital',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  ],
                ),
                const SizedBox(height: 16),
                LinearProgressIndicator(
                  value: progressoMedio / 100,
                  backgroundColor: AppColors.surfaceVariant,
                  color: AppColors.secondary,
                  minHeight: 10,
                  borderRadius: BorderRadius.circular(6),
                ),
                const SizedBox(height: 8),
                Text('$progressoMedio% do seu caminho concluído',
                    style: const TextStyle(color: AppColors.onSurfaceMuted)),
                if (emAndamento.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Text('Próximo passo: ${emAndamento.first.titulo}',
                      style: const TextStyle(color: AppColors.primaryLight)),
                ],
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        const Text('Atalhos', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        const SizedBox(height: 12),
        _atalho(Icons.auto_awesome_outlined, 'Recomendado para você',
            'Sugestões calculadas pelo motor de recomendação da IA', () {
          Navigator.push(context,
              MaterialPageRoute(builder: (_) => const RecomendacoesScreen()));
        }),
        _atalho(Icons.smart_toy_outlined, 'Assistente de IA',
            'Tire dúvidas sobre serviços e entregas', () {
          Navigator.push(context,
              MaterialPageRoute(builder: (_) => const AssistenteScreen()));
        }),
        _atalho(Icons.trending_up, 'Tendências e Sazonalidade',
            'Veja os picos de demanda detectados pela IA', () {
          Navigator.push(context,
              MaterialPageRoute(builder: (_) => const TendenciasScreen()));
        }),
        _atalho(Icons.notifications_active_outlined, 'Testar alerta (FCM/local)',
            'Simula uma notificação push do sistema', () {
          NotificationService.instance.mostrarNotificacao(
            titulo: 'Smart HAS - Aviso',
            corpo: 'Esta é uma notificação simulada do sistema Digital 360.',
          );
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Notificação disparada!')),
          );
        }),
        const SizedBox(height: 8),
        const Text('Comunidade', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        const SizedBox(height: 12),
        _atalho(Icons.forum_outlined, 'Fórum da comunidade',
            'Tire dúvidas e ajude outras pessoas', () {
          Navigator.push(context, MaterialPageRoute(builder: (_) => const ForumScreen()));
        }),
        _atalho(Icons.emoji_events_outlined, 'Minhas conquistas',
            'Cursos concluídos, sequência de dias e ranking', () {
          Navigator.push(context, MaterialPageRoute(builder: (_) => const ConquistasScreen()));
        }),
        _atalho(Icons.insights_outlined, 'Painel de impacto',
            'Números da comunidade Digital 360', () {
          Navigator.push(context, MaterialPageRoute(builder: (_) => const ImpactoScreen()));
        }),
      ],
    );
  }

  Widget _atalho(IconData icon, String titulo, String sub, VoidCallback onTap) {
    return Card(
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: AppColors.primary.withValues(alpha: 0.15),
          child: Icon(icon, color: AppColors.primary),
        ),
        title: Text(titulo, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text(sub),
        trailing: const Icon(Icons.chevron_right, color: AppColors.onSurfaceMuted),
        onTap: onTap,
      ),
    );
  }
}

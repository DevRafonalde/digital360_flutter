import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/cpf_utils.dart';
import '../../data/services/notification_service.dart';
import '../../providers/auth_provider.dart';
import '../../providers/curso_autoria_provider.dart';
import 'acompanhamento_screen.dart';
import 'configuracoes_screen.dart';
import 'creditos_screen.dart';
import 'indicacao_screen.dart';
import 'login_screen.dart';
import 'meus_cursos_screen.dart';
import 'privacidade_screen.dart';

class PerfilScreen extends StatefulWidget {
  const PerfilScreen({super.key});

  @override
  State<PerfilScreen> createState() => _PerfilScreenState();
}

class _PerfilScreenState extends State<PerfilScreen> {
  bool _cpfRevelado = false;

  Future<void> _editarNome(String nomeAtual) async {
    final ctrl = TextEditingController(text: nomeAtual);
    final novo = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Editar nome'),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          decoration: const InputDecoration(labelText: 'Como quer ser chamado?'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
          ElevatedButton(
              onPressed: () => Navigator.pop(ctx, ctrl.text.trim()), child: const Text('Salvar')),
        ],
      ),
    );
    if (novo != null && novo.isNotEmpty && mounted) {
      await context.read<AuthProvider>().atualizarNome(novo);
    }
  }

  Future<void> _confirmarLogout() async {
    final auth = context.read<AuthProvider>();
    final confirmou = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Sair da conta?'),
        content: const Text('Você precisará entrar novamente para acessar o app.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancelar')),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.riskCritical),
            child: const Text('Sair'),
          ),
        ],
      ),
    );
    if (confirmou != true || !mounted) return;
    await auth.logout();
    if (mounted) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen()),
        (route) => false,
      );
    }
  }

  Future<void> _tornarSeTutor() async {
    final confirmou = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Tornar-se tutor?'),
        content: const Text(
          'Como tutor, você poderá criar cursos e publicá-los direto para a '
          'comunidade, sem fila de aprovação. Essa ação não pode ser desfeita no app.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancelar')),
          ElevatedButton(onPressed: () => Navigator.pop(context, true), child: const Text('Confirmar')),
        ],
      ),
    );
    if (confirmou != true || !mounted) return;

    final auth = context.read<AuthProvider>();
    final autoria = context.read<CursoAutoriaProvider>();
    final ok = await autoria.tornarSeTutor(auth.usuario?.bearer ?? '');
    if (!mounted) return;
    if (ok) {
      await auth.marcarComoTutor();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Agora você é tutor! Pode criar cursos em "Meus cursos".')),
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(autoria.erro ?? 'Não foi possível ativar o modo tutor agora.')),
      );
    }
  }

  Future<void> _excluirConta() async {
    final confirmou = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Excluir sua conta?'),
        content: const Text(
          'Essa ação é permanente e não pode ser desfeita. Seus dados pessoais serão '
          'apagados. Cursos que você publicou como tutor continuam disponíveis para '
          'quem já os estuda, mas deixam de estar associados ao seu nome.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancelar')),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.riskCritical),
            child: const Text('Excluir permanentemente'),
          ),
        ],
      ),
    );
    if (confirmou != true || !mounted) return;

    final auth = context.read<AuthProvider>();
    final ok = await auth.excluirConta();
    if (!mounted) return;
    if (ok) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen()),
        (route) => false,
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Não foi possível excluir sua conta agora. Tente novamente.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final u = auth.usuario;
    return Scaffold(
      appBar: AppBar(title: const Text('Perfil')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Center(
            child: CircleAvatar(
              radius: 48,
              backgroundColor: AppColors.primary.withValues(alpha: 0.2),
              child: const Icon(Icons.person, size: 56, color: AppColors.primary),
            ),
          ),
          const SizedBox(height: 16),
          Center(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(u?.nomeAmigavel ?? 'Visitante',
                    style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                if (u != null) ...[
                  const SizedBox(width: 6),
                  InkWell(
                    onTap: () => _editarNome(u.nomeAmigavel),
                    child: const Icon(Icons.edit, size: 18, color: AppColors.onSurfaceMuted),
                  ),
                ],
              ],
            ),
          ),
          Center(
            child: Text('@${u?.nomeUser ?? ''}',
                style: const TextStyle(color: AppColors.onSurfaceMuted)),
          ),
          const SizedBox(height: 24),
          if (u != null && (u.cpf.isNotEmpty || u.nomeCompleto.isNotEmpty))
            Card(
              child: Column(
                children: [
                  if (u.nomeCompleto.isNotEmpty)
                    ListTile(
                      leading: const Icon(Icons.badge_outlined, color: AppColors.secondary),
                      title: const Text('Nome completo'),
                      subtitle: Text(u.nomeCompleto),
                    ),
                  if (u.cpf.isNotEmpty) ...[
                    if (u.nomeCompleto.isNotEmpty) const Divider(height: 1),
                    ListTile(
                      leading: const Icon(Icons.badge_outlined, color: AppColors.secondary),
                      title: const Text('CPF'),
                      subtitle: Text(_cpfRevelado ? u.cpf : cpfMascarado(u.cpf)),
                      trailing: IconButton(
                        icon: Icon(_cpfRevelado ? Icons.visibility_off_outlined : Icons.visibility_outlined),
                        tooltip: _cpfRevelado ? 'Ocultar CPF' : 'Mostrar CPF completo',
                        onPressed: () => setState(() => _cpfRevelado = !_cpfRevelado),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          const SizedBox(height: 16),
          if (u != null)
            Card(
              child: u.isTutor
                  ? ListTile(
                      leading: const Icon(Icons.school_outlined, color: AppColors.primary),
                      title: const Text('Meus cursos'),
                      subtitle: const Text('Você é tutor — crie e gerencie seus cursos'),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () => Navigator.push(context,
                          MaterialPageRoute(builder: (_) => const MeusCursosScreen())),
                    )
                  : ListTile(
                      leading: const Icon(Icons.co_present_outlined, color: AppColors.primary),
                      title: const Text('Tornar-se tutor'),
                      subtitle: const Text('Crie e publique seus próprios cursos'),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: _tornarSeTutor,
                    ),
            ),
          const SizedBox(height: 16),
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.family_restroom_outlined, color: AppColors.primary),
                  title: const Text('Modo cuidador'),
                  subtitle: const Text('Acompanhe o progresso de quem você cuida'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => Navigator.push(context,
                      MaterialPageRoute(builder: (_) => const AcompanhamentoScreen())),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.card_giftcard_outlined, color: AppColors.primary),
                  title: const Text('Indique um amigo'),
                  subtitle: const Text('Compartilhe seu código de indicação'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => Navigator.push(context,
                      MaterialPageRoute(builder: (_) => const IndicacaoScreen())),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.settings_outlined, color: AppColors.primary),
                  title: const Text('Configurações'),
                  subtitle: const Text('Tema, tamanho do texto, notificações'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => Navigator.push(context,
                      MaterialPageRoute(builder: (_) => const ConfiguracoesScreen())),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.notifications_outlined,
                      color: AppColors.accent),
                  title: const Text('Status do Firebase / FCM'),
                  subtitle: Text(NotificationService.instance.firebaseDisponivel
                      ? 'Conectado'
                      : 'Modo local (configure o google-services.json)'),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.privacy_tip_outlined, color: AppColors.secondary),
                  title: const Text('Política de Privacidade'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => Navigator.push(context,
                      MaterialPageRoute(builder: (_) => const PrivacidadeScreen())),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.info_outline, color: AppColors.secondary),
                  title: const Text('Créditos do aplicativo'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => Navigator.push(context,
                      MaterialPageRoute(builder: (_) => const CreditosScreen())),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          OutlinedButton.icon(
            onPressed: _confirmarLogout,
            icon: const Icon(Icons.logout),
            label: const Text('Sair'),
            style: OutlinedButton.styleFrom(
              minimumSize: const Size.fromHeight(50),
              foregroundColor: AppColors.riskCritical,
              side: const BorderSide(color: AppColors.riskCritical),
            ),
          ),
          if (u != null) ...[
            const SizedBox(height: 12),
            TextButton.icon(
              onPressed: _excluirConta,
              icon: const Icon(Icons.delete_forever_outlined),
              label: const Text('Excluir minha conta'),
              style: TextButton.styleFrom(
                minimumSize: const Size.fromHeight(50),
                foregroundColor: AppColors.riskCritical,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

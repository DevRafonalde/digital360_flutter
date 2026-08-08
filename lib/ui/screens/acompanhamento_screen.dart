import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../providers/auth_provider.dart';
import '../../providers/cuidador_provider.dart';
import '../widgets/empty_state.dart';

/// Modo cuidador: lista os idosos vinculados e o progresso (somente
/// leitura) de cada um. O cuidador nunca age em nome do idoso - só
/// acompanha.
class AcompanhamentoScreen extends StatefulWidget {
  const AcompanhamentoScreen({super.key});

  @override
  State<AcompanhamentoScreen> createState() => _AcompanhamentoScreenState();
}

class _AcompanhamentoScreenState extends State<AcompanhamentoScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _carregar());
  }

  Future<void> _carregar() async {
    final auth = context.read<AuthProvider>();
    await context.read<CuidadorProvider>().carregarVinculos(
          auth.usuario?.bearer ?? '',
          auth.usuario?.nomeUser ?? '',
        );
  }

  Future<void> _vincularNovoIdoso() async {
    final codigoCtrl = TextEditingController();
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Acompanhar alguém'),
        content: TextField(
          controller: codigoCtrl,
          decoration: const InputDecoration(
            labelText: 'Código de convite',
            hintText: 'Peça o nome de usuário da pessoa',
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
          ElevatedButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Vincular')),
        ],
      ),
    );
    if (confirmar != true || codigoCtrl.text.trim().isEmpty || !mounted) return;

    final auth = context.read<AuthProvider>();
    final provider = context.read<CuidadorProvider>();
    final ok = await provider.vincular(
      auth.usuario?.bearer ?? '',
      auth.usuario?.nomeUser ?? '',
      codigoCtrl.text.trim(),
    );
    if (!mounted) return;
    if (ok) {
      _carregar();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(provider.erro ?? 'Não foi possível vincular agora.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = context.watch<CuidadorProvider>();
    return Scaffold(
      appBar: AppBar(title: const Text('Modo cuidador')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _vincularNovoIdoso,
        icon: const Icon(Icons.person_add_alt_outlined),
        label: const Text('Acompanhar alguém'),
      ),
      body: p.carregando
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : RefreshIndicator(
              onRefresh: _carregar,
              child: p.vinculos.isEmpty
                  ? ListView(
                      children: const [
                        SizedBox(height: 80),
                        EmptyState(
                          icone: Icons.family_restroom_outlined,
                          titulo: 'Você ainda não acompanha ninguém',
                          subtitulo:
                              'Peça o nome de usuário da pessoa e use "Acompanhar alguém"',
                        ),
                      ],
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: p.vinculos.length,
                      itemBuilder: (_, i) {
                        final v = p.vinculos[i];
                        final resumo = p.resumos[v.idosoId];
                        return Card(
                          child: ListTile(
                            leading: const CircleAvatar(
                              backgroundColor: AppColors.surfaceVariant,
                              child: Icon(Icons.person_outline, color: AppColors.primary),
                            ),
                            title: Text(v.idosoNome),
                            subtitle: resumo == null
                                ? null
                                : Text(
                                    '${resumo.cursosConcluidos} cursos concluídos • ${resumo.sequenciaDias} dias seguidos',
                                  ),
                          ),
                        );
                      },
                    ),
            ),
    );
  }
}

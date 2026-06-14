import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../providers/auth_provider.dart';
import '../../providers/servicos_provider.dart';
import 'detalhe_servico_screen.dart';
import '../widgets/offline_banner.dart';

class GuiaScreen extends StatefulWidget {
  const GuiaScreen({super.key});

  @override
  State<GuiaScreen> createState() => _GuiaScreenState();
}

class _GuiaScreenState extends State<GuiaScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _carregar());
  }

  Future<void> _carregar() async {
    final auth = context.read<AuthProvider>();
    await context.read<ServicosProvider>().carregar(auth.usuario?.bearer ?? '');
  }

  @override
  Widget build(BuildContext context) {
    final p = context.watch<ServicosProvider>();
    return Column(
      children: [
        if (p.erro != null) const OfflineBanner(),
        Padding(
          padding: const EdgeInsets.all(16),
          child: TextField(
            decoration: const InputDecoration(
              hintText: 'Buscar serviço ou órgão...',
              prefixIcon: Icon(Icons.search),
            ),
            onChanged: p.filtrar,
          ),
        ),
        Expanded(
          child: p.carregando
              ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
              : p.servicos.isEmpty
                  ? const Center(child: Text('Nenhum serviço encontrado.'))
                  : RefreshIndicator(
                      onRefresh: _carregar,
                      child: ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: p.servicos.length,
                        itemBuilder: (_, i) {
                          final s = p.servicos[i];
                          final fav = p.favoritos.contains(s.id);
                          return Card(
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundColor:
                                    AppColors.accent.withOpacity(0.15),
                                child: const Icon(Icons.account_balance,
                                    color: AppColors.accent),
                              ),
                              title: Text(s.titulo,
                                  style: const TextStyle(fontWeight: FontWeight.w600)),
                              subtitle: Text('${s.orgao}  -  ${s.categoria}'),
                              trailing: IconButton(
                                icon: Icon(fav ? Icons.star : Icons.star_border,
                                    color: fav ? AppColors.primary : AppColors.onSurfaceMuted),
                                onPressed: () => p.alternarFavorito(s.id),
                              ),
                              onTap: () => Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                      builder: (_) => DetalheServicoScreen(servico: s))),
                            ),
                          );
                        },
                      ),
                    ),
        ),
      ],
    );
  }
}

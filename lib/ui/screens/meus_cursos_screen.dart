import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../providers/auth_provider.dart';
import '../../providers/curso_autoria_provider.dart';
import '../widgets/empty_state.dart';
import '../widgets/risk_badge.dart';
import 'criar_curso_screen.dart';

/// Lista os cursos que o usuário logado criou como tutor.
class MeusCursosScreen extends StatefulWidget {
  const MeusCursosScreen({super.key});

  @override
  State<MeusCursosScreen> createState() => _MeusCursosScreenState();
}

class _MeusCursosScreenState extends State<MeusCursosScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _carregar());
  }

  Future<void> _carregar() async {
    final auth = context.read<AuthProvider>();
    await context.read<CursoAutoriaProvider>().carregarMeusCursos(
          auth.usuario?.bearer ?? '',
          auth.usuario?.nomeUser ?? '',
        );
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
    final p = context.watch<CursoAutoriaProvider>();
    return Scaffold(
      appBar: AppBar(title: const Text('Meus cursos')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _criarCurso,
        icon: const Icon(Icons.add),
        label: const Text('Criar curso'),
      ),
      body: p.carregandoMeusCursos
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : RefreshIndicator(
              onRefresh: _carregar,
              child: p.meusCursos.isEmpty
                  ? ListView(
                      children: const [
                        SizedBox(height: 80),
                        EmptyState(
                          icone: Icons.menu_book_outlined,
                          titulo: 'Você ainda não criou nenhum curso',
                          subtitulo: 'Toque em "Criar curso" para publicar o primeiro',
                        ),
                      ],
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: p.meusCursos.length,
                      itemBuilder: (_, i) {
                        final c = p.meusCursos[i];
                        return Card(
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
                                if (c.descricao.isNotEmpty)
                                  Text(c.descricao, style: const TextStyle(color: AppColors.onSurface)),
                                const SizedBox(height: 8),
                                Text('${c.totalModulos} módulos  •  ${c.cargaHoraria}h  •  ${c.status}',
                                    style: const TextStyle(
                                        color: AppColors.onSurfaceMuted, fontSize: 12)),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),
    );
  }
}

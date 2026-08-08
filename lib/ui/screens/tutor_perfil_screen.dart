import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../data/models/avaliacao_curso.dart';
import '../../data/services/api_service.dart';
import '../../providers/auth_provider.dart';

/// Perfil público de um tutor: cursos publicados e média de avaliação
/// (marketplace de tutores).
class TutorPerfilScreen extends StatefulWidget {
  final String autorId;
  const TutorPerfilScreen({super.key, required this.autorId});

  @override
  State<TutorPerfilScreen> createState() => _TutorPerfilScreenState();
}

class _TutorPerfilScreenState extends State<TutorPerfilScreen> {
  bool _carregando = true;
  PerfilTutor? _perfil;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _carregar());
  }

  Future<void> _carregar() async {
    final auth = context.read<AuthProvider>();
    try {
      final perfil = await ApiService.instance.getPerfilTutor(auth.usuario?.bearer ?? '', widget.autorId);
      if (!mounted) return;
      setState(() => _perfil = perfil);
    } catch (_) {
      // perfil de tutor e informativo - falha silenciosa mantem a tela vazia
    } finally {
      if (mounted) setState(() => _carregando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final perfil = _perfil;
    return Scaffold(
      appBar: AppBar(title: const Text('Perfil do tutor')),
      body: _carregando
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : perfil == null
              ? const Center(child: Text('Não foi possível carregar este perfil.'))
              : ListView(
                  padding: const EdgeInsets.all(20),
                  children: [
                    Center(
                      child: CircleAvatar(
                        radius: 40,
                        backgroundColor: AppColors.primary.withValues(alpha: 0.15),
                        child: const Icon(Icons.co_present_outlined, size: 40, color: AppColors.primary),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Center(
                      child: Text(perfil.nomeAmigavel,
                          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                    ),
                    const SizedBox(height: 4),
                    const Center(
                      child: Text('Tutor da comunidade',
                          style: TextStyle(color: AppColors.onSurfaceMuted)),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        Expanded(
                          child: Card(
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                children: [
                                  Text('${perfil.totalCursos}',
                                      style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                                  const Text('Cursos publicados',
                                      style: TextStyle(color: AppColors.onSurfaceMuted, fontSize: 12)),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Card(
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                children: [
                                  Text(
                                    perfil.mediaAvaliacao?.toStringAsFixed(1) ?? '—',
                                    style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                                  ),
                                  Text('${perfil.totalAvaliacoes} avaliações',
                                      style: const TextStyle(color: AppColors.onSurfaceMuted, fontSize: 12)),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
    );
  }
}

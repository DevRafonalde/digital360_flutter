import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../data/models/avaliacao_curso.dart';
import '../../data/models/curso.dart';
import '../../data/services/api_service.dart';
import '../../data/services/certificado_service.dart';
import '../../data/services/tts_service.dart';
import '../../providers/auth_provider.dart';
import '../../providers/cursos_provider.dart';
import '../widgets/libras_video_placeholder.dart';
import '../widgets/risk_badge.dart';
import 'tutor_perfil_screen.dart';

class DetalheCursoScreen extends StatefulWidget {
  final Curso curso;
  const DetalheCursoScreen({super.key, required this.curso});

  @override
  State<DetalheCursoScreen> createState() => _DetalheCursoScreenState();
}

class _DetalheCursoScreenState extends State<DetalheCursoScreen> {
  List<AvaliacaoCurso> _avaliacoes = [];
  bool _carregandoAvaliacoes = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _carregarAvaliacoes());
  }

  @override
  void dispose() {
    TtsService.instance.parar();
    super.dispose();
  }

  Future<void> _carregarAvaliacoes() async {
    final auth = context.read<AuthProvider>();
    try {
      final avaliacoes = await ApiService.instance.getAvaliacoesCurso(
        auth.usuario?.bearer ?? '',
        widget.curso.id,
      );
      if (!mounted) return;
      setState(() => _avaliacoes = avaliacoes);
    } catch (_) {
      // avaliacoes sao um extra informativo - falha silenciosa
    } finally {
      if (mounted) setState(() => _carregandoAvaliacoes = false);
    }
  }

  Future<void> _avaliarCurso() async {
    int nota = 5;
    final comentarioCtrl = TextEditingController();
    final enviar = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('Avaliar este curso'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(5, (i) {
                  final estrela = i + 1;
                  return IconButton(
                    onPressed: () => setDialogState(() => nota = estrela),
                    icon: Icon(
                      estrela <= nota ? Icons.star : Icons.star_border,
                      color: AppColors.riskMedium,
                    ),
                  );
                }),
              ),
              TextField(
                controller: comentarioCtrl,
                decoration: const InputDecoration(labelText: 'Comentário (opcional)'),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
            ElevatedButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Enviar')),
          ],
        ),
      ),
    );
    if (enviar != true || !mounted) return;

    final auth = context.read<AuthProvider>();
    try {
      await ApiService.instance.avaliarCurso(
        auth.usuario?.bearer ?? '',
        widget.curso.id,
        auth.usuario?.nomeAmigavel ?? 'Visitante',
        nota,
        comentarioCtrl.text.trim().isEmpty ? null : comentarioCtrl.text.trim(),
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Avaliação enviada, obrigado!')),
      );
      _carregarAvaliacoes();
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Não foi possível enviar sua avaliação agora.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<CursosProvider>();
    // Busca a versao mais atual do curso no provider (o progresso muda ao
    // tocar em "Continuar"), caindo de volta pro objeto recebido se sumir.
    final curso = provider.cursos.firstWhere(
      (c) => c.id == widget.curso.id,
      orElse: () => widget.curso,
    );

    if (provider.cursoRecemConcluido?.id == curso.id) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        final auth = context.read<AuthProvider>();
        provider.registrarConclusao(
          auth.usuario?.bearer ?? '',
          auth.usuario?.nomeUser ?? 'visitante',
          curso.id,
        );
        provider.limparConclusaoRecente();
        _mostrarParabens(curso.titulo);
      });
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Detalhes do curso'),
        actions: [
          IconButton(
            tooltip: 'Ouvir',
            icon: const Icon(Icons.volume_up_outlined),
            onPressed: () => TtsService.instance.falar('${curso.titulo}. ${curso.descricao}'),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          NivelBadge(nivel: curso.nivel),
          const SizedBox(height: 12),
          Text(curso.titulo,
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          Text(curso.descricao, style: const TextStyle(color: AppColors.onSurface)),
          const SizedBox(height: 16),
          LibrasVideoPlaceholder(tituloConteudo: curso.titulo),
          if (curso.isComunidade && curso.autorId != null) ...[
            const SizedBox(height: 8),
            InkWell(
              onTap: () => Navigator.push(context,
                  MaterialPageRoute(builder: (_) => TutorPerfilScreen(autorId: curso.autorId!))),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.co_present_outlined, size: 16, color: AppColors.statusInTransit),
                  const SizedBox(width: 4),
                  Text('Criado por ${curso.autorId}',
                      style: const TextStyle(color: AppColors.statusInTransit, fontSize: 13)),
                ],
              ),
            ),
          ],
          const SizedBox(height: 24),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  _linha('Carga horária', '${curso.cargaHoraria} horas'),
                  _linha('Modulos', '${curso.totalModulos}'),
                  _linha('Progresso', '${curso.progresso}%'),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: curso.progresso / 100),
            duration: const Duration(milliseconds: 500),
            builder: (_, value, __) => LinearProgressIndicator(
              value: value,
              backgroundColor: AppColors.surfaceVariant,
              color: AppColors.secondary,
              minHeight: 10,
              borderRadius: BorderRadius.circular(6),
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: curso.progresso >= 100
                ? null
                : () => context.read<CursosProvider>().avancar(curso.id),
            icon: Icon(curso.progresso >= 100 ? Icons.check_circle : Icons.play_arrow),
            label: Text(curso.progresso >= 100
                ? 'Curso concluído'
                : curso.progresso > 0
                    ? 'Continuar curso'
                    : 'Começar curso'),
          ),
          if (curso.progresso >= 100) ...[
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: () => _baixarCertificado(curso),
              icon: const Icon(Icons.workspace_premium_outlined),
              label: const Text('Baixar certificado (PDF)'),
            ),
          ],
          const SizedBox(height: 32),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Avaliações', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              TextButton.icon(
                onPressed: _avaliarCurso,
                icon: const Icon(Icons.star_border),
                label: const Text('Avaliar'),
              ),
            ],
          ),
          if (_carregandoAvaliacoes)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: Center(child: CircularProgressIndicator(color: AppColors.primary)),
            )
          else if (_avaliacoes.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: Text('Nenhuma avaliação ainda. Seja o primeiro!',
                  style: TextStyle(color: AppColors.onSurfaceMuted)),
            )
          else
            for (final a in _avaliacoes)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(a.usuarioNome,
                              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                          const Spacer(),
                          Row(
                            children: List.generate(
                              5,
                              (i) => Icon(
                                i < a.nota ? Icons.star : Icons.star_border,
                                size: 14,
                                color: AppColors.riskMedium,
                              ),
                            ),
                          ),
                        ],
                      ),
                      if (a.comentario != null && a.comentario!.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(a.comentario!),
                      ],
                    ],
                  ),
                ),
              ),
        ],
      ),
    );
  }

  Future<void> _baixarCertificado(Curso curso) async {
    final auth = context.read<AuthProvider>();
    await CertificadoService.gerarEAbrir(
      nomeAluno: auth.usuario?.nomeCompleto.isNotEmpty == true
          ? auth.usuario!.nomeCompleto
          : (auth.usuario?.nomeAmigavel ?? 'Aluno(a)'),
      tituloCurso: curso.titulo,
      cargaHoraria: curso.cargaHoraria,
    );
  }

  void _mostrarParabens(String titulo) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        icon: TweenAnimationBuilder<double>(
          tween: Tween(begin: 0, end: 1),
          duration: const Duration(milliseconds: 400),
          curve: Curves.elasticOut,
          builder: (_, scale, child) => Transform.scale(scale: scale, child: child),
          child: const Icon(Icons.emoji_events, color: AppColors.secondary, size: 48),
        ),
        title: const Text('Parabéns!'),
        content: Text('Você concluiu o curso "$titulo". Continue sua jornada de inclusão digital!'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Fechar')),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.pop(context);
              _baixarCertificado(widget.curso);
            },
            icon: const Icon(Icons.workspace_premium_outlined),
            label: const Text('Certificado'),
          ),
        ],
      ),
    );
  }

  Widget _linha(String k, String v) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(k, style: const TextStyle(color: AppColors.onSurfaceMuted)),
            Text(v, style: const TextStyle(fontWeight: FontWeight.w600)),
          ],
        ),
      );
}

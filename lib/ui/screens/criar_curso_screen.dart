import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../providers/auth_provider.dart';
import '../../providers/curso_autoria_provider.dart';

const _niveis = ['BASICO', 'INTERMEDIARIO', 'AVANCADO'];
const _rotulosNivel = {
  'BASICO': 'Básico',
  'INTERMEDIARIO': 'Intermediário',
  'AVANCADO': 'Avançado',
};

/// Tela de criação de curso comunitário (Nível 2+4): o tutor descreve o
/// tema, pode pedir uma estrutura inicial gerada por template (heurística,
/// não IA generativa - deixado claro na tela), edita os módulos como quiser
/// e publica direto, sem fila de moderação.
class CriarCursoScreen extends StatefulWidget {
  const CriarCursoScreen({super.key});

  @override
  State<CriarCursoScreen> createState() => _CriarCursoScreenState();
}

class _CriarCursoScreenState extends State<CriarCursoScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titulo = TextEditingController();
  final _descricao = TextEditingController();
  final _cargaHoraria = TextEditingController(text: '4');
  String _nivel = 'BASICO';
  final List<TextEditingController> _modulos = [];

  @override
  void dispose() {
    _titulo.dispose();
    _descricao.dispose();
    _cargaHoraria.dispose();
    for (final c in _modulos) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _gerarEstruturaInicial() async {
    if (_titulo.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Escreva um título antes de gerar a estrutura.')),
      );
      return;
    }
    final auth = context.read<AuthProvider>();
    final provider = context.read<CursoAutoriaProvider>();
    await provider.gerarRascunho(auth.usuario?.bearer ?? '', _titulo.text.trim(), _nivel);
    if (!mounted) return;
    if (provider.rascunhoSugerido.isNotEmpty) {
      setState(() {
        for (final c in _modulos) {
          c.dispose();
        }
        _modulos
          ..clear()
          ..addAll(provider.rascunhoSugerido.map((t) => TextEditingController(text: t)));
      });
      provider.limparRascunho();
    } else if (provider.erro != null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(provider.erro!)));
    }
  }

  void _adicionarModulo() {
    setState(() => _modulos.add(TextEditingController()));
  }

  void _removerModulo(int i) {
    setState(() {
      _modulos[i].dispose();
      _modulos.removeAt(i);
    });
  }

  Future<void> _publicar() async {
    if (!_formKey.currentState!.validate()) return;
    final topicos = _modulos.map((c) => c.text.trim()).where((t) => t.isNotEmpty).toList();
    if (topicos.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Adicione ao menos um módulo antes de publicar.')),
      );
      return;
    }
    final auth = context.read<AuthProvider>();
    final provider = context.read<CursoAutoriaProvider>();
    final ok = await provider.publicarCurso(
      auth.usuario?.bearer ?? '',
      autorId: auth.usuario?.nomeUser ?? '',
      titulo: _titulo.text.trim(),
      descricao: _descricao.text.trim(),
      nivel: _nivel,
      cargaHoraria: int.tryParse(_cargaHoraria.text) ?? 0,
      topicosModulos: topicos,
    );
    if (!mounted) return;
    if (ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Curso publicado! Já está visível para todo mundo.')),
      );
      Navigator.pop(context, true);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(provider.erro ?? 'Não foi possível publicar agora.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<CursoAutoriaProvider>();
    return Scaffold(
      appBar: AppBar(title: const Text('Criar curso')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextFormField(
                controller: _titulo,
                decoration: const InputDecoration(labelText: 'Título do curso'),
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Campo obrigatório' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descricao,
                maxLines: 2,
                decoration: const InputDecoration(labelText: 'Descrição breve'),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      initialValue: _nivel,
                      decoration: const InputDecoration(labelText: 'Nível'),
                      items: _niveis
                          .map((n) => DropdownMenuItem(value: n, child: Text(_rotulosNivel[n]!)))
                          .toList(),
                      onChanged: (v) => setState(() => _nivel = v ?? 'BASICO'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _cargaHoraria,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'Carga horária (h)'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.surfaceVariant,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.info_outline, size: 18, color: AppColors.onSurfaceMuted),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Gera uma estrutura por modelo/regras — revise e edite antes de publicar. '
                        'Não é inteligência artificial generativa.',
                        style: TextStyle(fontSize: 12, color: AppColors.onSurfaceMuted),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: provider.gerandoRascunho ? null : _gerarEstruturaInicial,
                icon: provider.gerandoRascunho
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary),
                      )
                    : const Icon(Icons.auto_awesome_outlined),
                label: const Text('Gerar estrutura inicial'),
                style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(48)),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Módulos', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  TextButton.icon(
                    onPressed: _adicionarModulo,
                    icon: const Icon(Icons.add),
                    label: const Text('Adicionar'),
                  ),
                ],
              ),
              if (_modulos.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 12),
                  child: Text('Nenhum módulo ainda. Gere uma estrutura inicial ou adicione manualmente.',
                      style: TextStyle(color: AppColors.onSurfaceMuted)),
                ),
              for (int i = 0; i < _modulos.length; i++)
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _modulos[i],
                          decoration: InputDecoration(labelText: 'Módulo ${i + 1}'),
                        ),
                      ),
                      IconButton(
                        onPressed: () => _removerModulo(i),
                        icon: const Icon(Icons.delete_outline, color: AppColors.riskCritical),
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: provider.publicando ? null : _publicar,
                style: ElevatedButton.styleFrom(minimumSize: const Size.fromHeight(52)),
                child: provider.publicando
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.onPrimary),
                      )
                    : const Text('Publicar curso'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

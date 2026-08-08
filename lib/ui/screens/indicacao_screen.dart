import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import '../../core/theme/app_colors.dart';
import '../../data/services/api_service.dart';
import '../../providers/auth_provider.dart';

/// "Indique um amigo": mostra o código de indicação do usuário (o próprio
/// nome de usuário) e permite compartilhar via o share sheet genérico do
/// sistema operacional - não um link direto de nenhum app específico.
class IndicacaoScreen extends StatefulWidget {
  const IndicacaoScreen({super.key});

  @override
  State<IndicacaoScreen> createState() => _IndicacaoScreenState();
}

class _IndicacaoScreenState extends State<IndicacaoScreen> {
  bool _carregando = true;
  String _codigo = '';
  int _total = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _carregar());
  }

  Future<void> _carregar() async {
    final auth = context.read<AuthProvider>();
    final userId = auth.usuario?.nomeUser ?? '';
    try {
      final r = await ApiService.instance.getMinhasIndicacoes(auth.usuario?.bearer ?? '', userId);
      if (!mounted) return;
      setState(() {
        _codigo = r['codigo']?.toString() ?? userId;
        _total = r['totalIndicacoes'] ?? 0;
      });
    } finally {
      if (mounted) setState(() => _carregando = false);
    }
  }

  void _compartilhar() {
    SharePlus.instance.share(ShareParams(
      text: 'Estou usando o Digital 360 pra aprender tecnologia e acessar serviços '
          'públicos com mais facilidade! Use meu código "$_codigo" ao se cadastrar.',
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Indique um amigo')),
      body: _carregando
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : ListView(
              padding: const EdgeInsets.all(20),
              children: [
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      children: [
                        const Icon(Icons.card_giftcard_outlined, color: AppColors.primary, size: 40),
                        const SizedBox(height: 12),
                        const Text('Seu código de indicação',
                            style: TextStyle(color: AppColors.onSurfaceMuted)),
                        const SizedBox(height: 8),
                        Text(_codigo,
                            style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 20),
                        Text('$_total pessoa(s) já se cadastraram com seu código',
                            style: const TextStyle(color: AppColors.onSurfaceMuted)),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                ElevatedButton.icon(
                  onPressed: _compartilhar,
                  icon: const Icon(Icons.share_outlined),
                  label: const Text('Compartilhar código'),
                  style: ElevatedButton.styleFrom(minimumSize: const Size.fromHeight(52)),
                ),
              ],
            ),
    );
  }
}

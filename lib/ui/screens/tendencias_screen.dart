import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../providers/auth_provider.dart';
import '../../providers/logistica_provider.dart';

/// Vitrine da deteccao de picos/sazonalidade da AI Logistics Extension -
/// consome GET /tendencias, que ate agora nao tinha nenhuma tela no app.
class TendenciasScreen extends StatefulWidget {
  const TendenciasScreen({super.key});

  @override
  State<TendenciasScreen> createState() => _TendenciasScreenState();
}

class _TendenciasScreenState extends State<TendenciasScreen> {
  bool _carregando = true;
  String? _erro;
  List<Map<String, dynamic>> _tendencias = [];

  @override
  void initState() {
    super.initState();
    _carregar();
  }

  Future<void> _carregar() async {
    setState(() {
      _carregando = true;
      _erro = null;
    });
    try {
      final auth = context.read<AuthProvider>();
      final logistica = context.read<LogisticaProvider>();
      final r = await logistica.carregarTendencias(auth.usuario?.bearer ?? '');
      if (mounted) setState(() => _tendencias = r);
    } catch (e) {
      if (mounted) setState(() => _erro = 'Não conseguimos carregar as tendências agora.');
    } finally {
      if (mounted) setState(() => _carregando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Tendências e Sazonalidade')),
      body: RefreshIndicator(
        onRefresh: _carregar,
        child: _carregando
            ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
            : _erro != null
                ? ListView(children: [
                    const SizedBox(height: 120),
                    Center(child: Text(_erro!)),
                    Center(
                      child: TextButton(onPressed: _carregar, child: const Text('Tentar de novo')),
                    ),
                  ])
                : ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      const Text(
                        'Detecção automática de picos de demanda por categoria, '
                        'comparando o volume recente com a média histórica.',
                        style: TextStyle(color: AppColors.onSurfaceMuted),
                      ),
                      const SizedBox(height: 16),
                      ..._tendencias.map(_card),
                    ],
                  ),
      ),
    );
  }

  Widget _card(Map<String, dynamic> t) {
    final emAlta = t['emAlta'] == true;
    final cor = emAlta ? AppColors.riskHigh : AppColors.onSurfaceMuted;
    return Card(
      child: ListTile(
        leading: Icon(
          emAlta ? Icons.trending_up : Icons.trending_flat,
          color: cor,
        ),
        title: Text(t['categoria']?.toString() ?? '',
            style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text(
            'Últimos 7 dias: ${t['volumeUltimos7Dias']}  •  média histórica/dia: ${t['mediaHistoricaDiaria']}'),
        trailing: emAlta
            ? const Chip(
                label: Text('EM ALTA', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                backgroundColor: AppColors.riskHigh,
                labelStyle: TextStyle(color: Colors.white),
              )
            : null,
      ),
    );
  }
}

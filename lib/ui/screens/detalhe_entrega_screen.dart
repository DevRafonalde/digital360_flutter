import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../data/models/pedido_logistico.dart';
import '../../data/services/weather_service.dart';
import '../../data/services/viacep_service.dart';
import '../../providers/auth_provider.dart';
import '../../providers/logistica_provider.dart';
import '../widgets/risk_badge.dart';
import 'assistente_screen.dart';

/// Detalhe da entrega: dispara recalculo de risco (motor AI Logistics),
/// consulta o clima na regiao (Open-Meteo) e permite resolver endereco por CEP
/// (ViaCEP) - integrando os dois web services externos da Parte 6.
class DetalheEntregaScreen extends StatefulWidget {
  final PedidoLogistico pedido;
  const DetalheEntregaScreen({super.key, required this.pedido});

  @override
  State<DetalheEntregaScreen> createState() => _DetalheEntregaScreenState();
}

class _DetalheEntregaScreenState extends State<DetalheEntregaScreen> {
  final _weather = WeatherService();
  final _viacep = ViaCepService();
  final _cepCtrl = TextEditingController();

  RiscoLogistico? _risco;
  WeatherInfo? _clima;
  Endereco? _endereco;
  bool _calculando = false;
  String? _cepErro;

  @override
  void initState() {
    super.initState();
    _carregarClima();
  }

  @override
  void dispose() {
    _cepCtrl.dispose();
    super.dispose();
  }

  Future<void> _carregarClima() async {
    try {
      final c = await _weather.obterClima(
          widget.pedido.latitude, widget.pedido.longitude);
      if (mounted) setState(() => _clima = c);
    } catch (_) {/* clima opcional */}
  }

  Future<void> _recalcular() async {
    setState(() => _calculando = true);
    final auth = context.read<AuthProvider>();
    final logistica = context.read<LogisticaProvider>();
    final r = await logistica.recalcularRisco(
        auth.usuario?.bearer ?? '', widget.pedido);
    if (mounted) {
      setState(() {
        _risco = r;
        _calculando = false;
      });
    }
  }

  Future<void> _buscarCep() async {
    setState(() => _cepErro = null);
    try {
      final e = await _viacep.buscarPorCep(_cepCtrl.text);
      if (mounted) setState(() => _endereco = e);
    } catch (ex) {
      if (mounted) setState(() => _cepErro = ex.toString().replaceAll('Exception: ', ''));
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.pedido;
    return Scaffold(
      appBar: AppBar(title: Text(p.codigoPedido)),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(p.produto,
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              ),
              StatusChip(status: p.statusAtual),
            ],
          ),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  _linha('Região', p.regiaoEntrega),
                  _linha('Distância', '${p.distanciaKm} km'),
                  _linha('Prazo prometido', p.prazoPrometido),
                  _linha('Parceiro', p.parceiroLogistico),
                  _linha('Estoque', p.estoqueDisponivel ? 'Disponível' : 'Indisponível'),
                  _linha('Histórico de atrasos', '${p.historicoAtrasos}'),
                  _linha('Reagendamentos', '${p.reagendamentos}'),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // ---- Web Service 1: Open-Meteo (clima) ----
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  const Icon(Icons.cloud_outlined, color: AppColors.accent),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _clima == null
                        ? const Text('Consultando clima na região (Open-Meteo)...')
                        : Text(
                            'Clima: ${_clima!.temperatura.toStringAsFixed(0)} C, '
                            '${_clima!.descricao}\n'
                            'Impacto no risco: +${_clima!.impactoRisco}',
                            style: const TextStyle(height: 1.4),
                          ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // ---- Motor de risco (AI Logistics) ----
          if (_risco != null)
            Card(
              color: AppColors.surfaceVariant,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    RiskBadge(nivel: _risco!.riscoNivel, score: _risco!.riscoScore),
                    const SizedBox(height: 10),
                    Text(_risco!.recomendacao, style: const TextStyle(height: 1.4)),
                    const SizedBox(height: 6),
                    Text(_risco!.mensagemCliente,
                        style: const TextStyle(
                            color: AppColors.onSurfaceMuted, fontStyle: FontStyle.italic)),
                  ],
                ),
              ),
            ),
          const SizedBox(height: 12),
          ElevatedButton.icon(
            onPressed: _calculando ? null : _recalcular,
            icon: _calculando
                ? const SizedBox(
                    height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : const Icon(Icons.calculate_outlined),
            label: const Text('Recalcular risco de entrega'),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) => AssistenteScreen(pedidoId: p.id))),
            icon: const Icon(Icons.smart_toy_outlined),
            label: const Text('Perguntar ao assistente logístico'),
            style: OutlinedButton.styleFrom(
              minimumSize: const Size.fromHeight(50),
              foregroundColor: AppColors.secondary,
              side: const BorderSide(color: AppColors.secondary),
            ),
          ),
          const SizedBox(height: 20),

          // ---- Web Service 2: ViaCEP (endereco) ----
          const Text('Validar endereço de entrega (ViaCEP)',
              style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _cepCtrl,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                      hintText: 'CEP (ex: 01001-000)', errorText: _cepErro),
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                  onPressed: _buscarCep,
                  style: ElevatedButton.styleFrom(minimumSize: const Size(80, 56)),
                  child: const Text('Buscar')),
            ],
          ),
          if (_endereco != null)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Text(_endereco!.completo,
                  style: const TextStyle(color: AppColors.secondary)),
            ),
        ],
      ),
    );
  }

  Widget _linha(String k, String v) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 5),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(k, style: const TextStyle(color: AppColors.onSurfaceMuted)),
            Flexible(child: Text(v, textAlign: TextAlign.right, style: const TextStyle(fontWeight: FontWeight.w600))),
          ],
        ),
      );
}

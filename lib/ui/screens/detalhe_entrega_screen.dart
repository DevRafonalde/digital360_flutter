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
/// consulta o clima na regiao (Open-Meteo, e o resultado agora realmente
/// entra na conta do risco) e permite resolver endereco por CEP (ViaCEP) -
/// integrando os dois web services externos da Parte 6.
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
  String? _climaErro;
  Endereco? _endereco;
  bool _calculando = false;
  bool _reagendando = false;
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
    setState(() => _climaErro = null);
    try {
      final c = await _weather.obterClima(
          widget.pedido.latitude, widget.pedido.longitude);
      if (mounted) setState(() => _clima = c);
    } catch (_) {
      if (mounted) setState(() => _climaErro = 'Clima indisponível no momento.');
    }
  }

  Future<void> _recalcular() async {
    setState(() => _calculando = true);
    final auth = context.read<AuthProvider>();
    final logistica = context.read<LogisticaProvider>();
    // O impacto do clima (0-25) so entra na conta se a consulta deu certo -
    // sem isso, o texto "impacto no risco" na tela era so decoracao.
    final impactoClima = _clima?.impactoRisco ?? 0;
    final r = await logistica.recalcularRisco(
        auth.usuario?.bearer ?? '', widget.pedido, impactoClima: impactoClima);
    if (mounted) {
      setState(() {
        _risco = r;
        _calculando = false;
      });
    }
  }

  Future<void> _confirmarReagendar() async {
    final confirmou = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Reagendar entrega?'),
        content: Text(
            'Vamos reagendar o pedido ${widget.pedido.codigoPedido} e reiniciar o acompanhamento de risco.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancelar')),
          ElevatedButton(onPressed: () => Navigator.pop(context, true), child: const Text('Confirmar')),
        ],
      ),
    );
    if (confirmou != true || !mounted) return;

    setState(() => _reagendando = true);
    final auth = context.read<AuthProvider>();
    final logistica = context.read<LogisticaProvider>();
    await logistica.reagendar(auth.usuario?.bearer ?? '', widget.pedido);
    if (!mounted) return;
    setState(() {
      _reagendando = false;
      _risco = null;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Entrega reagendada com sucesso.')),
    );
  }

  Future<void> _abrirFeedback() async {
    int nota = 5;
    final comentarioCtrl = TextEditingController();
    final enviar = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('Como foi sua entrega?'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(5, (i) {
                  final valor = i + 1;
                  return IconButton(
                    onPressed: () => setDialogState(() => nota = valor),
                    icon: Icon(
                      valor <= nota ? Icons.star : Icons.star_border,
                      color: AppColors.primary,
                    ),
                  );
                }),
              ),
              TextField(
                controller: comentarioCtrl,
                decoration: const InputDecoration(hintText: 'Comentário (opcional)'),
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
    final logistica = context.read<LogisticaProvider>();
    await logistica.enviarFeedback(
        auth.usuario?.bearer ?? '', widget.pedido.id, nota, comentarioCtrl.text.trim());
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Obrigado pelo seu feedback!')),
    );
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
    final riscoAtual = _risco ?? context.watch<LogisticaProvider>().riscos[p.id];
    final podeReagendar = riscoAtual != null &&
        (riscoAtual.riscoNivel == 'ALTO' || riscoAtual.riscoNivel == 'CRITICO');

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
                    child: _climaErro != null
                        ? Row(
                            children: [
                              Expanded(child: Text(_climaErro!)),
                              TextButton(onPressed: _carregarClima, child: const Text('Tentar de novo')),
                            ],
                          )
                        : _clima == null
                            ? const Text('Consultando clima na região (Open-Meteo)...')
                            : Text(
                                'Clima: ${_clima!.temperatura.toStringAsFixed(0)} °C, '
                                '${_clima!.descricao}\n'
                                'Impacto no risco: +${_clima!.impactoRisco} (já considerado no cálculo)',
                                style: const TextStyle(height: 1.4),
                              ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // ---- Motor de risco (AI Logistics) ----
          if (riscoAtual != null)
            Card(
              color: AppColors.surfaceVariant,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    RiskBadge(nivel: riscoAtual.riscoNivel, score: riscoAtual.riscoScore),
                    const SizedBox(height: 10),
                    Text(riscoAtual.recomendacao, style: const TextStyle(height: 1.4)),
                    const SizedBox(height: 6),
                    Text(riscoAtual.mensagemCliente,
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
          if (podeReagendar) ...[
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: _reagendando ? null : _confirmarReagendar,
              icon: _reagendando
                  ? const SizedBox(
                      height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Icon(Icons.event_repeat),
              label: const Text('Reagendar entrega'),
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.riskHigh),
            ),
          ],
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
          if (p.statusAtual == 'ENTREGUE') ...[
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: _abrirFeedback,
              icon: const Icon(Icons.star_outline),
              label: const Text('Avaliar esta entrega'),
              style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(50)),
            ),
          ],
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

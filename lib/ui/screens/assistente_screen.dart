import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/theme/app_colors.dart';
import '../../providers/auth_provider.dart';
import '../../providers/logistica_provider.dart';

/// Assistente de IA (chat). Para duvidas gerais (pedidoId nulo) ou sobre um
/// pedido especifico. Usa o endpoint /assistente-logistico/pergunta.
class AssistenteScreen extends StatefulWidget {
  final int? pedidoId;
  const AssistenteScreen({super.key, this.pedidoId});

  @override
  State<AssistenteScreen> createState() => _AssistenteScreenState();
}

class _Mensagem {
  final String texto;
  final bool doUsuario;
  _Mensagem(this.texto, this.doUsuario);

  Map<String, dynamic> toJson() => {'texto': texto, 'doUsuario': doUsuario};
  factory _Mensagem.fromJson(Map<String, dynamic> j) => _Mensagem(j['texto'], j['doUsuario']);
}

class _AssistenteScreenState extends State<AssistenteScreen> {
  final _ctrl = TextEditingController();
  final _scroll = ScrollController();
  final List<_Mensagem> _msgs = [];
  bool _enviando = false;
  bool _carregouHistorico = false;
  int? _pedidoSelecionado;

  String get _chavePrefs => 'chat_historico_${widget.pedidoId ?? _pedidoSelecionado ?? "geral"}';

  @override
  void initState() {
    super.initState();
    _pedidoSelecionado = widget.pedidoId;
    _carregarHistorico();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    _scroll.dispose();
    super.dispose();
  }

  Future<void> _carregarHistorico() async {
    try {
      final p = await SharedPreferences.getInstance();
      final raw = p.getString(_chavePrefs);
      if (raw != null) {
        final list = (jsonDecode(raw) as List).map((e) => _Mensagem.fromJson(e)).toList();
        if (mounted) setState(() => _msgs.addAll(list));
      }
    } catch (_) {/* primeira vez / dado corrompido - comeca do zero */}
    if (_msgs.isEmpty) {
      _msgs.add(_Mensagem(
          'Olá! Sou o assistente do Digital 360. Pergunte sobre seus '
          'cursos, serviços públicos ou suas entregas.',
          false));
    }
    if (mounted) setState(() => _carregouHistorico = true);
    _rolarParaFinal();
  }

  Future<void> _salvarHistorico() async {
    try {
      final p = await SharedPreferences.getInstance();
      await p.setString(_chavePrefs, jsonEncode(_msgs.map((m) => m.toJson()).toList()));
    } catch (_) {/* ignora falha de disco */}
  }

  void _rolarParaFinal() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scroll.hasClients) return;
      _scroll.animateTo(
        _scroll.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    });
  }

  Future<void> _enviar() async {
    final txt = _ctrl.text.trim();
    if (txt.isEmpty) return;
    setState(() {
      _msgs.add(_Mensagem(txt, true));
      _enviando = true;
      _ctrl.clear();
    });
    _rolarParaFinal();
    final auth = context.read<AuthProvider>();
    final logistica = context.read<LogisticaProvider>();
    try {
      final r = await logistica.perguntar(
          auth.usuario?.bearer ?? '', _pedidoSelecionado ?? 0, txt);
      setState(() {
        _msgs.add(_Mensagem(
            '${r['resposta']}\n\nAção recomendada: ${r['acaoRecomendada']}', false));
      });
    } catch (e) {
      setState(() => _msgs.add(_Mensagem('Não consegui responder agora.', false)));
    } finally {
      setState(() => _enviando = false);
      _rolarParaFinal();
      _salvarHistorico();
    }
  }

  @override
  Widget build(BuildContext context) {
    final pedidos = context.watch<LogisticaProvider>().pedidos;
    return Scaffold(
      appBar: AppBar(title: const Text('Assistente de IA')),
      body: Column(
        children: [
          if (widget.pedidoId == null && pedidos.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
              child: SizedBox(
                height: 40,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: [
                    _chipPedido(null, 'Pergunta geral'),
                    ...pedidos.map((p) => _chipPedido(p.id, p.codigoPedido)),
                  ],
                ),
              ),
            ),
          Expanded(
            child: !_carregouHistorico
                ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
                : ListView.builder(
                    controller: _scroll,
                    padding: const EdgeInsets.all(16),
                    itemCount: _msgs.length,
                    itemBuilder: (_, i) {
                      final m = _msgs[i];
                      return Align(
                        alignment:
                            m.doUsuario ? Alignment.centerRight : Alignment.centerLeft,
                        child: Container(
                          margin: const EdgeInsets.symmetric(vertical: 6),
                          padding: const EdgeInsets.all(12),
                          constraints: const BoxConstraints(maxWidth: 280),
                          decoration: BoxDecoration(
                            color: m.doUsuario
                                ? AppColors.primary
                                : AppColors.surfaceCard,
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Text(m.texto,
                              style: TextStyle(
                                  color: m.doUsuario
                                      ? Colors.white
                                      : AppColors.onBackground,
                                  height: 1.4)),
                        ),
                      );
                    },
                  ),
          ),
          if (_enviando)
            const Padding(
              padding: EdgeInsets.all(8),
              child: Text('Digitando...', style: TextStyle(color: AppColors.onSurfaceMuted)),
            ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _ctrl,
                      decoration: const InputDecoration(hintText: 'Escreva sua dúvida...'),
                      onSubmitted: (_) => _enviar(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  FloatingActionButton(
                    onPressed: _enviar,
                    backgroundColor: AppColors.primary,
                    child: const Icon(Icons.send, color: Colors.white),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _chipPedido(int? pedidoId, String rotulo) {
    final selecionado = _pedidoSelecionado == pedidoId;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Text(rotulo),
        selected: selecionado,
        onSelected: (_) => setState(() => _pedidoSelecionado = pedidoId),
      ),
    );
  }
}

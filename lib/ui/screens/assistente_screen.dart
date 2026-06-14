import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
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
}

class _AssistenteScreenState extends State<AssistenteScreen> {
  final _ctrl = TextEditingController();
  final List<_Mensagem> _msgs = [
    _Mensagem('Olá! Sou o assistente do Digital 360. Pergunte sobre seus '
        'cursos, serviços públicos ou suas entregas.', false),
  ];
  bool _enviando = false;

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _enviar() async {
    final txt = _ctrl.text.trim();
    if (txt.isEmpty) return;
    setState(() {
      _msgs.add(_Mensagem(txt, true));
      _enviando = true;
      _ctrl.clear();
    });
    final auth = context.read<AuthProvider>();
    final logistica = context.read<LogisticaProvider>();
    try {
      final r = await logistica.perguntar(
          auth.usuario?.bearer ?? '', widget.pedidoId ?? 0, txt);
      setState(() {
        _msgs.add(_Mensagem(
            '${r['resposta']}\n\nAção recomendada: ${r['acaoRecomendada']}', false));
      });
    } catch (e) {
      setState(() => _msgs.add(_Mensagem('Não consegui responder agora.', false)));
    } finally {
      setState(() => _enviando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Assistente de IA')),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
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
}

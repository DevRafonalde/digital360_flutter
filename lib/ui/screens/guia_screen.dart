import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:speech_to_text/speech_to_text.dart';
import '../../core/theme/app_colors.dart';
import '../../providers/auth_provider.dart';
import '../../providers/recomendacoes_provider.dart';
import '../../providers/servicos_provider.dart';
import 'detalhe_servico_screen.dart';
import '../widgets/offline_banner.dart';
import '../widgets/empty_state.dart';

class GuiaScreen extends StatefulWidget {
  const GuiaScreen({super.key});

  @override
  State<GuiaScreen> createState() => _GuiaScreenState();
}

class _GuiaScreenState extends State<GuiaScreen> {
  final _buscaCtrl = TextEditingController();
  final _speech = SpeechToText();
  bool _ouvindo = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _carregar());
  }

  @override
  void dispose() {
    _buscaCtrl.dispose();
    _speech.stop();
    super.dispose();
  }

  Future<void> _carregar() async {
    final auth = context.read<AuthProvider>();
    await context.read<ServicosProvider>().carregar(auth.usuario?.bearer ?? '');
  }

  /// Busca por voz - util para quem tem dificuldade de digitar. Protegida
  /// com try/catch: se o dispositivo/navegador nao suportar, so avisa e
  /// segue com a busca por texto normalmente.
  Future<void> _alternarBuscaPorVoz(ServicosProvider p) async {
    if (_ouvindo) {
      await _speech.stop();
      setState(() => _ouvindo = false);
      return;
    }
    try {
      final disponivel = await _speech.initialize();
      if (!disponivel) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Busca por voz indisponível neste dispositivo.')),
          );
        }
        return;
      }
      setState(() => _ouvindo = true);
      await _speech.listen(
        onResult: (r) {
          _buscaCtrl.text = r.recognizedWords;
          p.filtrar(r.recognizedWords);
          if (r.finalResult && mounted) setState(() => _ouvindo = false);
        },
        listenOptions: SpeechListenOptions(localeId: 'pt_BR'),
      );
    } catch (_) {
      if (mounted) setState(() => _ouvindo = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = context.watch<ServicosProvider>();
    return Column(
      children: [
        if (p.erro != null) OfflineBanner(mensagem: p.erro!),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: TextField(
            controller: _buscaCtrl,
            decoration: InputDecoration(
              hintText: 'Buscar serviço ou órgão...',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: IconButton(
                tooltip: 'Buscar por voz',
                icon: Icon(_ouvindo ? Icons.mic : Icons.mic_none,
                    color: _ouvindo ? AppColors.primary : null),
                onPressed: () => _alternarBuscaPorVoz(p),
              ),
            ),
            onChanged: p.filtrar,
            onSubmitted: (v) => p.registrarBusca(v),
          ),
        ),
        if (_buscaCtrl.text.isEmpty && p.historicoBuscas.isNotEmpty)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Buscas recentes',
                        style: TextStyle(color: AppColors.onSurfaceMuted, fontSize: 12)),
                    InkWell(
                      onTap: p.limparHistorico,
                      child: const Text('Limpar',
                          style: TextStyle(color: AppColors.onSurfaceMuted, fontSize: 12)),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  children: p.historicoBuscas
                      .map((termo) => ActionChip(
                            label: Text(termo),
                            onPressed: () {
                              _buscaCtrl.text = termo;
                              p.filtrar(termo);
                              p.registrarBusca(termo);
                              setState(() {});
                            },
                          ))
                      .toList(),
                ),
              ],
            ),
          ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Align(
            alignment: Alignment.centerLeft,
            child: FilterChip(
              label: const Text('Somente favoritos'),
              avatar: Icon(p.apenasFavoritos ? Icons.star : Icons.star_border,
                  size: 18, color: p.apenasFavoritos ? AppColors.primary : null),
              selected: p.apenasFavoritos,
              onSelected: (_) => p.alternarFiltroFavoritos(),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Expanded(
          child: p.carregando
              ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
              : p.servicos.isEmpty
                  ? EmptyState(
                      icone: p.apenasFavoritos ? Icons.star_border : Icons.search_off,
                      titulo: p.apenasFavoritos
                          ? 'Você ainda não favoritou nenhum serviço'
                          : 'Nenhum serviço encontrado',
                      subtitulo: p.apenasFavoritos
                          ? 'Toque na estrela de um serviço para adicioná-lo aqui'
                          : 'Tente buscar por outro termo',
                    )
                  : RefreshIndicator(
                      onRefresh: _carregar,
                      child: ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: p.servicos.length,
                        itemBuilder: (_, i) {
                          final s = p.servicos[i];
                          final fav = p.favoritos.contains(s.id);
                          return Card(
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundColor:
                                    AppColors.accent.withValues(alpha: 0.15),
                                child: const Icon(Icons.account_balance,
                                    color: AppColors.accent),
                              ),
                              title: Text(s.titulo,
                                  style: const TextStyle(fontWeight: FontWeight.w600)),
                              subtitle: Text('${s.orgao}  -  ${s.categoria}'),
                              trailing: IconButton(
                                icon: Icon(fav ? Icons.star : Icons.star_border,
                                    color: fav ? AppColors.primary : AppColors.onSurfaceMuted),
                                onPressed: () => p.alternarFavorito(s.id),
                              ),
                              onTap: () {
                                final auth = context.read<AuthProvider>();
                                context.read<RecomendacoesProvider>().registrarVisita(
                                      auth.usuario?.bearer ?? '',
                                      userId: auth.usuario?.nomeUser ?? 'visitante',
                                      tipo: 'servico',
                                      referenceId: s.id,
                                      categoria: s.categoria,
                                    );
                                Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                        builder: (_) => DetalheServicoScreen(servico: s)));
                              },
                            ),
                          );
                        },
                      ),
                    ),
        ),
      ],
    );
  }
}

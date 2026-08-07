import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'core/navigation/navigator_key.dart';
import 'data/services/analytics_service.dart';
import 'data/services/notification_service.dart';
import 'providers/auth_provider.dart';
import 'providers/cursos_provider.dart';
import 'providers/servicos_provider.dart';
import 'providers/logistica_provider.dart';
import 'providers/settings_provider.dart';
import 'providers/recomendacoes_provider.dart';
import 'providers/curso_autoria_provider.dart';
import 'providers/forum_provider.dart';
import 'providers/gamificacao_provider.dart';
import 'providers/cuidador_provider.dart';
import 'app.dart';
import 'ui/screens/detalhe_entrega_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Inicializa Firebase + Cloud Messaging + notificacoes locais (Parte 6).
  // Encapsulado em try/catch para o app rodar mesmo sem google-services.json
  // configurado (ambiente de avaliacao).
  await NotificationService.instance.init();
  // Analytics + Crashlytics - depende do Firebase ja inicializado acima.
  await AnalyticsService.instance.init();

  // Deep link: tocar numa notificacao de risco abre a tela do pedido. O
  // servico de notificacao so repassa o payload (id do pedido) - a
  // navegacao em si fica aqui, na camada de UI.
  NotificationService.instance.onNotificacaoTocada = (payload) {
    final pedidoId = int.tryParse(payload ?? '');
    final context = navigatorKey.currentContext;
    if (pedidoId == null || context == null) return;

    final auth = Provider.of<AuthProvider>(context, listen: false);
    final logistica = Provider.of<LogisticaProvider>(context, listen: false);

    Future<void> abrirDetalhe() async {
      if (logistica.pedidos.isEmpty) {
        await logistica.carregar(auth.usuario?.bearer ?? '');
      }
      final encontrados = logistica.pedidos.where((p) => p.id == pedidoId);
      if (encontrados.isEmpty) return;
      navigatorKey.currentState?.push(
        MaterialPageRoute(builder: (_) => DetalheEntregaScreen(pedido: encontrados.first)),
      );
    }

    abrirDetalhe();
  };

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => CursosProvider()),
        ChangeNotifierProvider(create: (_) => ServicosProvider()),
        ChangeNotifierProvider(create: (_) => LogisticaProvider()),
        ChangeNotifierProvider(create: (_) => SettingsProvider()),
        ChangeNotifierProvider(create: (_) => RecomendacoesProvider()),
        ChangeNotifierProvider(create: (_) => CursoAutoriaProvider()),
        ChangeNotifierProvider(create: (_) => ForumProvider()),
        ChangeNotifierProvider(create: (_) => GamificacaoProvider()),
        ChangeNotifierProvider(create: (_) => CuidadorProvider()),
      ],
      child: const Digital360App(),
    ),
  );
}

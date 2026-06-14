import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'data/services/notification_service.dart';
import 'providers/auth_provider.dart';
import 'providers/cursos_provider.dart';
import 'providers/servicos_provider.dart';
import 'providers/logistica_provider.dart';
import 'app.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Inicializa Firebase + Cloud Messaging + notificacoes locais (Parte 6).
  // Encapsulado em try/catch para o app rodar mesmo sem google-services.json
  // configurado (ambiente de avaliacao).
  await NotificationService.instance.init();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => CursosProvider()),
        ChangeNotifierProvider(create: (_) => ServicosProvider()),
        ChangeNotifierProvider(create: (_) => LogisticaProvider()),
      ],
      child: const Digital360App(),
    ),
  );
}

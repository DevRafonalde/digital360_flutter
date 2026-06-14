import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

/// Handler de mensagens recebidas em background (exigido pelo FCM).
@pragma('vm:entry-point')
Future<void> _firebaseBackgroundHandler(RemoteMessage message) async {
  // Em background o Flutter sobe um isolate proprio; apenas logamos.
  debugPrint('FCM background: ${message.notification?.title}');
}

/// Servico de notificacoes (Parte 6).
/// Integra Firebase Core + Firebase Cloud Messaging + notificacoes locais.
/// Toda a inicializacao e protegida: se o google-services.json ainda nao
/// estiver configurado, o app continua funcionando normalmente.
class NotificationService {
  NotificationService._();
  static final NotificationService instance = NotificationService._();

  final FlutterLocalNotificationsPlugin _local =
      FlutterLocalNotificationsPlugin();
  bool _firebaseOk = false;

  Future<void> init() async {
    // 1) Notificacoes locais (sempre disponiveis).
    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const initSettings = InitializationSettings(android: androidInit);
    try {
      await _local.initialize(initSettings);
    } catch (e) {
      debugPrint('Local notifications init falhou: $e');
    }

    // 2) Firebase + FCM (opcional - depende de google-services.json).
    try {
      await Firebase.initializeApp();
      _firebaseOk = true;

      final messaging = FirebaseMessaging.instance;
      await messaging.requestPermission();
      FirebaseMessaging.onBackgroundMessage(_firebaseBackgroundHandler);

      // Mensagem recebida com o app aberto -> exibe notificacao local.
      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        final n = message.notification;
        if (n != null) {
          mostrarNotificacao(
            titulo: n.title ?? 'Smart HAS',
            corpo: n.body ?? '',
          );
        }
      });

      final token = await messaging.getToken();
      debugPrint('FCM token: $token');
    } catch (e) {
      debugPrint('Firebase/FCM nao configurado (seguindo sem push): $e');
    }
  }

  bool get firebaseDisponivel => _firebaseOk;

  /// Dispara uma notificacao local. Usada para simular um alerta/aviso do
  /// sistema (ex.: "Pedido com risco ALTO de atraso"), conforme a Parte 6.
  Future<void> mostrarNotificacao({
    required String titulo,
    required String corpo,
  }) async {
    const androidDetails = AndroidNotificationDetails(
      'smart_has_alertas',
      'Alertas Smart HAS',
      channelDescription: 'Alertas de logística e avisos do sistema',
      importance: Importance.max,
      priority: Priority.high,
      color: Color.fromARGB(255, 255, 107, 53),
    );
    const details = NotificationDetails(android: androidDetails);
    try {
      await _local.show(
        DateTime.now().millisecondsSinceEpoch ~/ 1000,
        titulo,
        corpo,
        details,
      );
    } catch (e) {
      debugPrint('Falha ao exibir notificacao: $e');
    }
  }
}

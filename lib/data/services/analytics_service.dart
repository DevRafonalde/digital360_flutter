import 'package:flutter/foundation.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';

/// Analytics + Crashlytics (Firebase). Mesmo padrao defensivo ja usado pro
/// FCM em NotificationService: toda inicializacao e protegida por try/catch,
/// entao o app continua funcionando normalmente sem google-services.json
/// configurado. NAO verificavel ponta-a-ponta neste ambiente de
/// desenvolvimento (o google-services.json do projeto e um placeholder, sem
/// projeto Firebase real por tras) - documentado assim no README.
class AnalyticsService {
  AnalyticsService._();
  static final AnalyticsService instance = AnalyticsService._();

  FirebaseAnalytics? _analytics;
  bool _crashlyticsOk = false;

  /// So configura Analytics/Crashlytics - assume que Firebase.initializeApp()
  /// ja rodou (feito por NotificationService.init(), chamado antes deste no
  /// main()). Se o Firebase nao tiver inicializado, cai no catch e o app
  /// segue sem telemetria, sem quebrar nada.
  Future<void> init() async {
    try {
      _analytics = FirebaseAnalytics.instance;
      FlutterError.onError = FirebaseCrashlytics.instance.recordFlutterFatalError;
      PlatformDispatcher.instance.onError = (erro, pilha) {
        FirebaseCrashlytics.instance.recordError(erro, pilha, fatal: true);
        return true;
      };
      _crashlyticsOk = true;
    } catch (e) {
      debugPrint('Analytics/Crashlytics nao configurado (seguindo sem telemetria): $e');
    }
  }

  bool get disponivel => _crashlyticsOk;

  /// Loga um evento de uso (ex.: "login_realizado", "curso_concluido").
  Future<void> logEvento(String nome, {Map<String, Object>? parametros}) async {
    try {
      await _analytics?.logEvent(name: nome, parameters: parametros);
    } catch (e) {
      debugPrint('Falha ao logar evento de analytics: $e');
    }
  }

  /// Registra um erro tratado (nao-fatal) no Crashlytics - usado em pontos
  /// onde o app ja se recupera sozinho, mas vale saber que o erro aconteceu.
  Future<void> registrarErro(Object erro, StackTrace pilha, {String? razao}) async {
    try {
      await FirebaseCrashlytics.instance.recordError(erro, pilha, reason: razao);
    } catch (e) {
      debugPrint('Falha ao registrar erro no Crashlytics: $e');
    }
  }
}

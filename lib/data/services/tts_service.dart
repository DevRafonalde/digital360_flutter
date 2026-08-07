import 'package:flutter_tts/flutter_tts.dart';

/// Leitura em voz alta (acessibilidade para baixo letramento digital).
/// Todas as chamadas sao protegidas - se o motor de TTS nao estiver
/// disponivel na plataforma/navegador, o app so ignora, sem quebrar a tela.
class TtsService {
  TtsService._();
  static final TtsService instance = TtsService._();

  final FlutterTts _tts = FlutterTts();
  bool _configurado = false;

  Future<void> _configurar() async {
    if (_configurado) return;
    try {
      await _tts.setLanguage('pt-BR');
      await _tts.setSpeechRate(0.45);
      await _tts.setPitch(1.0);
      _configurado = true;
    } catch (_) {/* segue sem TTS configurado - falara com config padrao ou nada */}
  }

  Future<void> falar(String texto) async {
    await _configurar();
    try {
      await _tts.stop();
      await _tts.speak(texto);
    } catch (_) {/* TTS indisponivel nesta plataforma - ignora silenciosamente */}
  }

  Future<void> parar() async {
    try {
      await _tts.stop();
    } catch (_) {}
  }
}

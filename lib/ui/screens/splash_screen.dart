import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/theme/app_colors.dart';
import '../../data/services/biometria_service.dart';
import '../../providers/auth_provider.dart';
import '../../providers/settings_provider.dart';
import '../widgets/wordmark.dart';
import 'home_screen.dart';
import 'login_screen.dart';
import 'onboarding_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  /// Quando a sessao ja esta autenticada mas a biometria esta ativa e ainda
  /// nao foi confirmada, o app fica preso nessa tela pedindo confirmacao -
  /// nao navega pra Home nem desfaz a sessao ja salva sozinho.
  bool _aguardandoBiometria = false;
  String? _erroBiometria;

  @override
  void initState() {
    super.initState();
    _iniciar();
  }

  Future<void> _iniciar() async {
    final auth = context.read<AuthProvider>();
    final sessaoFuture = auth.tentarSessaoSalva();
    final prefsFuture = SharedPreferences.getInstance();
    // O splash so espera o maximo entre a checagem de sessao e os 2s de
    // marca - nao soma os dois tempos (antes, um auth lento deixava a tela
    // presa por mais de 2s sem motivo).
    await Future.wait([sessaoFuture, Future.delayed(const Duration(seconds: 2))]);
    if (!mounted) return;

    final p = await prefsFuture;
    if (!mounted) return;
    final onboardingVisto = p.getBool('onboarding_visto') ?? false;

    if (auth.autenticado) {
      final settings = context.read<SettingsProvider>();
      if (settings.biometriaAtiva) {
        setState(() => _aguardandoBiometria = true);
        await _confirmarBiometria();
        return;
      }
      _irPara(const HomeScreen());
      return;
    }

    _irPara(!onboardingVisto ? const OnboardingScreen() : const LoginScreen());
  }

  Future<void> _confirmarBiometria() async {
    setState(() => _erroBiometria = null);
    final ok = await BiometriaService.instance.autenticar(
      motivo: 'Confirme sua identidade para acessar o Digital 360',
    );
    if (!mounted) return;
    if (ok) {
      _irPara(const HomeScreen());
    } else {
      setState(() => _erroBiometria = 'Não foi possível confirmar. Tente novamente.');
    }
  }

  Future<void> _entrarComSenha() async {
    // Sai da sessao salva e vai pro login normal - so usado quando a
    // biometria falha e a pessoa nao consegue/quer usar o dedo/rosto.
    await context.read<AuthProvider>().logout();
    if (!mounted) return;
    _irPara(const LoginScreen());
  }

  void _irPara(Widget destino) {
    Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => destino));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 96,
              height: 96,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppColors.primary, AppColors.primaryDark],
                ),
                borderRadius: BorderRadius.circular(24),
              ),
              child: const Icon(Icons.hub, color: Colors.white, size: 52),
            ),
            const SizedBox(height: 24),
            const Wordmark(fontSize: 32),
            const SizedBox(height: 8),
            const Text('Inclusão Digital para a Sociedade 5.0',
                style: TextStyle(color: AppColors.onSurfaceMuted)),
            const SizedBox(height: 40),
            if (_aguardandoBiometria) ...[
              const Icon(Icons.fingerprint, color: AppColors.primary, size: 40),
              const SizedBox(height: 12),
              if (_erroBiometria != null) ...[
                Text(_erroBiometria!, style: const TextStyle(color: AppColors.riskCritical)),
                const SizedBox(height: 12),
                ElevatedButton(
                  onPressed: _confirmarBiometria,
                  child: const Text('Tentar novamente'),
                ),
                const SizedBox(height: 8),
                TextButton(
                  onPressed: _entrarComSenha,
                  child: const Text('Entrar com usuário e senha'),
                ),
              ],
            ] else
              const CircularProgressIndicator(color: AppColors.primary),
          ],
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../providers/auth_provider.dart';
import '../widgets/wordmark.dart';
import 'home_screen.dart';
import 'register_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _user = TextEditingController();
  final _senha = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _user.dispose();
    _senha.dispose();
    super.dispose();
  }

  Future<void> _esqueciSenha() async {
    final ctrl = TextEditingController(text: _user.text);
    final nomeUser = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Recuperar senha'),
        content: TextField(
          controller: ctrl,
          decoration: const InputDecoration(labelText: 'Nome de usuário'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
          ElevatedButton(
              onPressed: () => Navigator.pop(ctx, ctrl.text.trim()), child: const Text('Enviar')),
        ],
      ),
    );
    if (nomeUser == null || nomeUser.isEmpty || !mounted) return;
    final msg = await context.read<AuthProvider>().solicitarRecuperacaoSenha(nomeUser);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  Future<void> _entrar({bool demo = false}) async {
    final auth = context.read<AuthProvider>();
    bool ok;
    if (demo) {
      ok = await auth.entrarDemo();
    } else {
      if (!_formKey.currentState!.validate()) return;
      ok = await auth.login(_user.text.trim(), _senha.text);
    }
    if (!mounted) return;
    if (ok) {
      Navigator.pushReplacement(
          context, MaterialPageRoute(builder: (_) => const HomeScreen()));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(auth.erro ?? 'Falha no login')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  const SizedBox(height: 20),
                  Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                          colors: [AppColors.primary, AppColors.primaryDark]),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Icon(Icons.hub, color: Colors.white, size: 40),
                  ),
                  const SizedBox(height: 16),
                  const Wordmark(fontSize: 28),
                  const Text('Inclusão Digital para a Sociedade 5.0',
                      style: TextStyle(color: AppColors.onSurfaceMuted)),
                  const SizedBox(height: 32),
                  TextFormField(
                    controller: _user,
                    decoration: const InputDecoration(
                        labelText: 'Nome de usuário',
                        prefixIcon: Icon(Icons.person_outline)),
                    validator: (v) =>
                        (v == null || v.isEmpty) ? 'Informe o usuário' : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _senha,
                    obscureText: true,
                    decoration: const InputDecoration(
                        labelText: 'Senha',
                        prefixIcon: Icon(Icons.lock_outline)),
                    validator: (v) =>
                        (v == null || v.isEmpty) ? 'Informe a senha' : null,
                  ),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: _esqueciSenha,
                      child: const Text('Esqueci minha senha'),
                    ),
                  ),
                  const SizedBox(height: 8),
                  ElevatedButton(
                    onPressed: auth.status == AuthStatus.loading
                        ? null
                        : () => _entrar(),
                    child: auth.status == AuthStatus.loading
                        ? const SizedBox(
                            height: 22,
                            width: 22,
                            child: CircularProgressIndicator(
                                color: Colors.white, strokeWidth: 2))
                        : const Text('Entrar'),
                  ),
                  const SizedBox(height: 12),
                  OutlinedButton(
                    onPressed: () => _entrar(demo: true),
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size.fromHeight(52),
                      side: const BorderSide(color: AppColors.secondary),
                      foregroundColor: AppColors.secondary,
                    ),
                    child: const Text('Entrar em modo demonstração'),
                  ),
                  const SizedBox(height: 12),
                  TextButton(
                    onPressed: () => Navigator.push(context,
                        MaterialPageRoute(builder: (_) => const RegisterScreen())),
                    child: const Text('Não tem conta? Cadastre-se',
                        style: TextStyle(color: AppColors.accent)),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

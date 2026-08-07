import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/cpf_utils.dart';
import '../../providers/auth_provider.dart';
import 'privacidade_screen.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _cpf = TextEditingController();
  final _nomeCompleto = TextEditingController();
  final _nomeAmigavel = TextEditingController();
  final _user = TextEditingController();
  final _senha = TextEditingController();
  final _confirma = TextEditingController();
  final _codigoIndicacao = TextEditingController();
  bool _aceitouPolitica = false;

  @override
  void dispose() {
    for (final c in [_cpf, _nomeCompleto, _nomeAmigavel, _user, _senha, _confirma, _codigoIndicacao]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _cadastrar() async {
    if (!_formKey.currentState!.validate()) return;
    if (!_aceitouPolitica) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('É necessário aceitar a Política de Privacidade para se cadastrar.')),
      );
      return;
    }
    final ok = await context.read<AuthProvider>().registrar({
      'cpf': _cpf.text.trim(),
      'nomeCompleto': _nomeCompleto.text.trim(),
      'nomeAmigavel': _nomeAmigavel.text.trim(),
      'nomeUser': _user.text.trim(),
      'senhaUser': _senha.text,
      'ativo': true,
      'aceitouPolitica': true,
      if (_codigoIndicacao.text.trim().isNotEmpty) 'codigoIndicacao': _codigoIndicacao.text.trim(),
    });
    if (!mounted) return;
    if (ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cadastro realizado! Faça login.')),
      );
      Navigator.pop(context);
    } else {
      final erro = context.read<AuthProvider>().erro;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(erro ?? 'Não foi possível concluir o cadastro.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Cadastro')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              _campo(_cpf, 'CPF', Icons.badge_outlined,
                  tipo: TextInputType.number,
                  formatadores: [CpfInputFormatter()],
                  validadorExtra: (v) => cpfValido(v) ? null : 'CPF inválido'),
              _campo(_nomeCompleto, 'Nome completo', Icons.person_outline),
              _campo(_nomeAmigavel, 'Como quer ser chamado?', Icons.tag_faces_outlined),
              _campo(_user, 'Nome de usuário', Icons.alternate_email),
              _campo(_senha, 'Senha', Icons.lock_outline, senha: true),
              _campo(_confirma, 'Confirmar senha', Icons.lock_outline,
                  senha: true, confirma: true),
              Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: TextFormField(
                  controller: _codigoIndicacao,
                  decoration: const InputDecoration(
                    labelText: 'Código de indicação (opcional)',
                    prefixIcon: Icon(Icons.card_giftcard_outlined),
                  ),
                ),
              ),
              CheckboxListTile(
                value: _aceitouPolitica,
                onChanged: (v) => setState(() => _aceitouPolitica = v ?? false),
                controlAffinity: ListTileControlAffinity.leading,
                contentPadding: EdgeInsets.zero,
                title: Text.rich(
                  TextSpan(
                    style: DefaultTextStyle.of(context).style,
                    children: [
                      const TextSpan(text: 'Li e aceito a '),
                      TextSpan(
                        text: 'Política de Privacidade',
                        style: const TextStyle(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w600,
                            decoration: TextDecoration.underline),
                        recognizer: TapGestureRecognizer()
                          ..onTap = () => Navigator.push(context,
                              MaterialPageRoute(builder: (_) => const PrivacidadeScreen())),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              ElevatedButton(onPressed: _cadastrar, child: const Text('Cadastrar-se')),
            ],
          ),
        ),
      ),
    );
  }

  Widget _campo(TextEditingController c, String label, IconData icon,
      {bool senha = false,
      bool confirma = false,
      TextInputType? tipo,
      List<TextInputFormatter>? formatadores,
      String? Function(String)? validadorExtra}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextFormField(
        controller: c,
        obscureText: senha,
        keyboardType: tipo,
        inputFormatters: formatadores,
        decoration: InputDecoration(labelText: label, prefixIcon: Icon(icon)),
        validator: (v) {
          if (v == null || v.isEmpty) return 'Campo obrigatório';
          if (confirma && v != _senha.text) return 'As senhas não conferem';
          if (validadorExtra != null) return validadorExtra(v);
          return null;
        },
      ),
    );
  }
}

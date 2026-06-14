import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';

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

  @override
  void dispose() {
    for (final c in [_cpf, _nomeCompleto, _nomeAmigavel, _user, _senha, _confirma]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _cadastrar() async {
    if (!_formKey.currentState!.validate()) return;
    final ok = await context.read<AuthProvider>().registrar({
      'cpf': _cpf.text.trim(),
      'nomeCompleto': _nomeCompleto.text.trim(),
      'nomeAmigavel': _nomeAmigavel.text.trim(),
      'nomeUser': _user.text.trim(),
      'senhaUser': _senha.text,
      'ativo': true,
    });
    if (!mounted) return;
    if (ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cadastro realizado! Faça login.')),
      );
      Navigator.pop(context);
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
              _campo(_cpf, 'CPF', Icons.badge_outlined, tipo: TextInputType.number),
              _campo(_nomeCompleto, 'Nome completo', Icons.person_outline),
              _campo(_nomeAmigavel, 'Como quer ser chamado?', Icons.tag_faces_outlined),
              _campo(_user, 'Nome de usuário', Icons.alternate_email),
              _campo(_senha, 'Senha', Icons.lock_outline, senha: true),
              _campo(_confirma, 'Confirmar senha', Icons.lock_outline,
                  senha: true, confirma: true),
              const SizedBox(height: 24),
              ElevatedButton(onPressed: _cadastrar, child: const Text('Cadastrar-se')),
            ],
          ),
        ),
      ),
    );
  }

  Widget _campo(TextEditingController c, String label, IconData icon,
      {bool senha = false, bool confirma = false, TextInputType? tipo}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextFormField(
        controller: c,
        obscureText: senha,
        keyboardType: tipo,
        decoration: InputDecoration(labelText: label, prefixIcon: Icon(icon)),
        validator: (v) {
          if (v == null || v.isEmpty) return 'Campo obrigatório';
          if (confirma && v != _senha.text) return 'As senhas não conferem';
          return null;
        },
      ),
    );
  }
}

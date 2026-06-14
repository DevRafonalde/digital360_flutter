import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import 'inicio_tab.dart';
import 'cursos_screen.dart';
import 'guia_screen.dart';
import 'logistica_screen.dart';
import 'mapa_screen.dart';
import 'perfil_screen.dart';

/// Casca principal com BottomNavigationBar (equivalente ao MainActivity +
/// BottomNavigationView do projeto Kotlin).
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _index = 0;

  final _telas = const [
    InicioTab(),
    CursosScreen(),
    GuiaScreen(),
    LogisticaScreen(),
    MapaScreen(),
  ];

  final _titulos = const ['Início', 'Cursos', 'Serviços', 'Logística', 'Mapa'];

  String _saudacao() {
    final h = DateTime.now().hour;
    if (h < 12) return 'Bom dia';
    if (h < 18) return 'Boa tarde';
    return 'Boa noite';
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    return Scaffold(
      appBar: AppBar(
        title: Text(_index == 0
            ? '${_saudacao()}, ${auth.usuario?.nomeAmigavel ?? ''}'
            : _titulos[_index]),
        actions: [
          IconButton(
            icon: const Icon(Icons.person_outline),
            onPressed: () => Navigator.push(context,
              MaterialPageRoute(builder: (_) => const PerfilScreen())),
          ),
        ],
      ),
      body: IndexedStack(index: _index, children: _telas),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _index,
        onTap: (i) => setState(() => _index = i),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home_outlined), label: 'Início'),
          BottomNavigationBarItem(icon: Icon(Icons.school_outlined), label: 'Cursos'),
          BottomNavigationBarItem(icon: Icon(Icons.account_balance_outlined), label: 'Serviços'),
          BottomNavigationBarItem(icon: Icon(Icons.local_shipping_outlined), label: 'Logística'),
          BottomNavigationBarItem(icon: Icon(Icons.map_outlined), label: 'Mapa'),
        ],
      ),
    );
  }
}

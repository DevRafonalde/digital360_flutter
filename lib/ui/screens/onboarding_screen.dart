import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/theme/app_colors.dart';
import 'login_screen.dart';

class _Slide {
  final IconData icone;
  final String titulo;
  final String texto;
  const _Slide(this.icone, this.titulo, this.texto);
}

const _slidesFixos = [
  _Slide(Icons.school_outlined, 'Aprenda no seu ritmo',
      'Trilhas simples sobre celular, internet e serviços públicos, com progresso salvo.'),
  _Slide(Icons.account_balance_outlined, 'Serviços públicos sem complicação',
      'Guia com passo a passo do INSS, gov.br, SUS e muito mais.'),
];

/// Dica final personalizada conforme o perfil escolhido no primeiro passo -
/// cada publico se beneficia de um destaque diferente do app.
const _dicasPorPerfil = {
  'idoso': _Slide(Icons.local_shipping_outlined, 'Acompanhe suas entregas',
      'Veja o risco de atraso em tempo real e converse com o assistente de IA quando precisar.'),
  'cuidador': _Slide(Icons.family_restroom_outlined, 'Acompanhe quem você cuida',
      'Ative o Modo Cuidador em Perfil para ver o progresso de quem você acompanha, sem mexer na conta dela.'),
  'pcd': _Slide(Icons.record_voice_over_outlined, 'Use sua voz',
      'Leitura em voz alta e busca por voz estão disponíveis nos cursos e no Guia de Serviços.'),
};

const _kOnboardingVisto = 'onboarding_visto';
const _kOnboardingPerfil = 'onboarding_perfil'; // 'idoso' | 'cuidador' | 'pcd'

/// Tour de boas-vindas exibido uma unica vez, antes do primeiro login. O
/// primeiro passo pergunta o perfil do usuario (idoso sozinho, cuidador ou
/// pessoa com deficiencia) - a escolha personaliza a dica final, e fica
/// salva para uso futuro (ex.: sugerir o Modo Cuidador no app).
class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _pageCtrl = PageController();
  int _pagina = 0;
  String? _perfil;

  List<_Slide> get _slides => [
        ..._slidesFixos,
        _dicasPorPerfil[_perfil] ?? _dicasPorPerfil['idoso']!,
      ];

  int get _totalPaginas => _slides.length + 1; // +1 pela pagina de perfil

  Future<void> _concluir() async {
    final p = await SharedPreferences.getInstance();
    await p.setBool(_kOnboardingVisto, true);
    if (_perfil != null) await p.setString(_kOnboardingPerfil, _perfil!);
    if (mounted) {
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const LoginScreen()));
    }
  }

  void _escolherPerfil(String perfil) {
    setState(() => _perfil = perfil);
    _pageCtrl.nextPage(duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
  }

  @override
  void dispose() {
    _pageCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Align(
              alignment: Alignment.topRight,
              child: TextButton(onPressed: _concluir, child: const Text('Pular')),
            ),
            Expanded(
              child: PageView.builder(
                controller: _pageCtrl,
                physics: _pagina == 0
                    ? const NeverScrollableScrollPhysics() // exige escolher o perfil pra avancar
                    : const AlwaysScrollableScrollPhysics(),
                itemCount: _totalPaginas,
                onPageChanged: (i) => setState(() => _pagina = i),
                itemBuilder: (_, i) {
                  if (i == 0) return _paginaPerfil();
                  final s = _slides[i - 1];
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 120,
                          height: 120,
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.15),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(s.icone, size: 56, color: AppColors.primary),
                        ),
                        const SizedBox(height: 32),
                        Text(s.titulo,
                            textAlign: TextAlign.center,
                            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 12),
                        Text(s.texto,
                            textAlign: TextAlign.center,
                            style: const TextStyle(color: AppColors.onSurfaceMuted, height: 1.4)),
                      ],
                    ),
                  );
                },
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                _totalPaginas,
                (i) => Container(
                  margin: const EdgeInsets.all(4),
                  width: i == _pagina ? 20 : 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: i == _pagina ? AppColors.primary : AppColors.surfaceVariant,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(24),
              child: _pagina == 0
                  ? const SizedBox(
                      height: 48,
                      child: Center(
                        child: Text('Escolha uma opção acima para continuar',
                            style: TextStyle(color: AppColors.onSurfaceMuted, fontSize: 12)),
                      ),
                    )
                  : ElevatedButton(
                      onPressed: () {
                        if (_pagina == _totalPaginas - 1) {
                          _concluir();
                        } else {
                          _pageCtrl.nextPage(
                              duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
                        }
                      },
                      child: Text(_pagina == _totalPaginas - 1 ? 'Começar' : 'Próximo'),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _paginaPerfil() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text('Quem vai usar o Digital 360?',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          const Text('Isso nos ajuda a mostrar as dicas certas para você',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.onSurfaceMuted)),
          const SizedBox(height: 28),
          _opcaoPerfil('idoso', Icons.person_outline, 'Eu mesmo(a)',
              'Vou usar o app para aprender e acessar serviços'),
          const SizedBox(height: 12),
          _opcaoPerfil('cuidador', Icons.family_restroom_outlined, 'Sou cuidador(a)',
              'Quero acompanhar o progresso de alguém'),
          const SizedBox(height: 12),
          _opcaoPerfil('pcd', Icons.accessibility_new_outlined, 'Pessoa com deficiência',
              'Quero saber sobre os recursos de acessibilidade'),
        ],
      ),
    );
  }

  Widget _opcaoPerfil(String valor, IconData icone, String titulo, String subtitulo) {
    return Card(
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: AppColors.primary.withValues(alpha: 0.15),
          child: Icon(icone, color: AppColors.primary),
        ),
        title: Text(titulo, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text(subtitulo),
        trailing: const Icon(Icons.chevron_right),
        onTap: () => _escolherPerfil(valor),
      ),
    );
  }
}

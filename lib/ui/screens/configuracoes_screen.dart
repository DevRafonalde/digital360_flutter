import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/api_constants.dart';
import '../../core/theme/app_colors.dart';
import '../../data/services/biometria_service.dart';
import '../../providers/logistica_provider.dart';
import '../../providers/settings_provider.dart';

/// Configuracoes de acessibilidade e notificacoes - itens que faltavam:
/// alternar tema, ajustar tamanho de fonte e ligar/desligar notificacoes.
class ConfiguracoesScreen extends StatelessWidget {
  const ConfiguracoesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsProvider>();
    final logistica = context.watch<LogisticaProvider>();

    return Scaffold(
      appBar: AppBar(title: const Text('Configurações')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text('Aparência', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 8),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Tema'),
                  const SizedBox(height: 12),
                  SegmentedButton<ThemeMode>(
                    segments: const [
                      ButtonSegment(
                        value: ThemeMode.system,
                        label: Text('Sistema'),
                        icon: Icon(Icons.brightness_auto_outlined),
                      ),
                      ButtonSegment(
                        value: ThemeMode.light,
                        label: Text('Claro'),
                        icon: Icon(Icons.light_mode_outlined),
                      ),
                      ButtonSegment(
                        value: ThemeMode.dark,
                        label: Text('Escuro'),
                        icon: Icon(Icons.dark_mode_outlined),
                      ),
                    ],
                    selected: {settings.themeMode},
                    onSelectionChanged: (novo) => settings.definirTema(novo.first),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          const Text('Tamanho do texto', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 8),
          Card(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Exemplo de texto com o tamanho escolhido',
                      style: TextStyle(fontSize: 16 * settings.fontScale)),
                  Slider(
                    value: settings.fontScale,
                    min: 0.9,
                    max: 1.3,
                    divisions: 4,
                    label: _rotuloFonte(settings.fontScale),
                    onChanged: settings.definirEscalaFonte,
                  ),
                  const Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Pequeno', style: TextStyle(color: AppColors.onSurfaceMuted, fontSize: 12)),
                      Text('Extra grande', style: TextStyle(color: AppColors.onSurfaceMuted, fontSize: 12)),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          const Text('Notificações', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 8),
          Card(
            child: SwitchListTile(
              secondary: const Icon(Icons.notifications_active_outlined, color: AppColors.accent),
              title: const Text('Receber alertas de entrega'),
              subtitle: const Text('Avisos quando o risco de uma entrega ficar alto ou crítico'),
              value: logistica.notificacoesAtivas,
              onChanged: logistica.definirNotificacoesAtivas,
            ),
          ),
          const SizedBox(height: 20),
          const Text('Segurança', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 8),
          FutureBuilder<bool>(
            future: BiometriaService.instance.disponivel(),
            builder: (context, snapshot) {
              final disponivel = snapshot.data ?? false;
              return Card(
                child: SwitchListTile(
                  secondary: const Icon(Icons.fingerprint, color: AppColors.primary),
                  title: const Text('Pedir biometria ao abrir o app'),
                  subtitle: Text(disponivel
                      ? 'Reautentica sua sessão salva com digital ou reconhecimento facial'
                      : 'Indisponível neste dispositivo'),
                  value: disponivel && settings.biometriaAtiva,
                  onChanged: disponivel ? settings.definirBiometriaAtiva : null,
                ),
              );
            },
          ),
          const SizedBox(height: 20),
          const Text('Conexão (avançado)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 8),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Backend usado pelo app'),
                  const SizedBox(height: 12),
                  SegmentedButton<AmbienteBackend>(
                    segments: const [
                      ButtonSegment(
                        value: AmbienteBackend.mock,
                        label: Text('Mock'),
                        icon: Icon(Icons.cloud_off_outlined),
                      ),
                      ButtonSegment(
                        value: AmbienteBackend.python,
                        label: Text('Python'),
                        icon: Icon(Icons.cloud_outlined),
                      ),
                      ButtonSegment(
                        value: AmbienteBackend.java,
                        label: Text('Java'),
                        icon: Icon(Icons.cloud_queue_outlined),
                      ),
                    ],
                    selected: {settings.ambienteBackend},
                    onSelectionChanged: (novo) => settings.definirAmbienteBackend(novo.first),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _descricaoAmbiente(settings.ambienteBackend),
                    style: const TextStyle(color: AppColors.onSurfaceMuted, fontSize: 12),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _descricaoAmbiente(AmbienteBackend ambiente) => switch (ambiente) {
        AmbienteBackend.mock => 'Sem backend: usa dados de demonstração salvos no app.',
        AmbienteBackend.python =>
          'Backend real do time (FastAPI) - cobre todas as áreas do app.',
        AmbienteBackend.java =>
          'Backend Spring Boot (Fase 5) - cobre login, cursos, serviços e AI Logistics.',
      };

  String _rotuloFonte(double v) {
    if (v <= 0.95) return 'Pequeno';
    if (v <= 1.05) return 'Médio';
    if (v <= 1.2) return 'Grande';
    return 'Extra grande';
  }
}

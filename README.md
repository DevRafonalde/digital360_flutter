# Digital 360 - Smart HAS (Flutter) | FIAP Fase 4

App mobile em **Flutter/Dart** do projeto **Smart HAS / Digital 360 - AI Logistics Extension**
(Sociedade 5.0, parceria Leroy Merlin). Reimplementacao da versao anterior feita em Kotlin.

## Grupo
- Eduardo Andrade Martins Vasques - RM 556970
- Otavio Ramos dos Santos Souza - RM 550361
- Enzo Miranda Ward de Paiva - RM 557632
- Rafael Pinto de Albuquerque - RM 559136
- Guilherme Leoni Vidigal Tiburcio - RM 557500

## Como o projeto atende a Fase 4
| Parte | Onde esta no codigo |
|------|----------------------|
| P4 - Flutter (widgets, estado, componentizacao) | `lib/ui/`, `lib/providers/` (Provider/ChangeNotifier) |
| P4 - Padrao de estado | **Provider** - 1 ChangeNotifier por dominio (auth, cursos, servicos, logistica) |
| P5 - Mapas e geolocalizacao | `lib/ui/screens/mapa_screen.dart` + `lib/data/services/location_service.dart` |
| P6 - 2+ web services | `weather_service.dart` (Open-Meteo) e `viacep_service.dart` (ViaCEP) - ambos reais e sem chave |
| P6 - Firebase + FCM push | `lib/data/services/notification_service.dart` (Firebase Core + FCM + notificacao local) |

## Arquitetura (camadas)
```
lib/
  core/        -> tema (cores Smart HAS), constantes, rede
  data/
    models/    -> Usuario, Curso, Servico, PedidoLogistico, RiscoLogistico
    services/  -> ApiService (mock+real), WeatherService, ViaCepService,
                  NotificationService (FCM), LocationService, SessionService
  providers/   -> AuthProvider, CursosProvider, ServicosProvider, LogisticaProvider
  ui/
    screens/   -> Splash, Login, Register, Home (bottom nav), Cursos+detalhe,
                  Guia+detalhe, Logistica+detalhe entrega, Assistente, Mapa,
                  Perfil, Creditos
    widgets/   -> RiskBadge, StatusChip, NivelBadge
```
Fluxo: **UI -> Provider (estado) -> Service (rede) -> Model**. Equivale ao MVVM
(ViewModel/Repository) do projeto Kotlin original.

## Rodar o projeto
> Requer Flutter SDK 3.3+ instalado (`flutter --version`).

1. Gere o scaffolding nativo (cria as pastas android/ios que faltam **sem apagar `lib/`**):
   ```bash
   flutter create . --org br.com.fiap --project-name digital360_flutter
   ```
   Depois **reaplique** os arquivos ja prontos deste repo:
   `android/app/src/main/AndroidManifest.xml`, `android/app/build.gradle`,
   `android/settings.gradle`, `android/app/google-services.json`.
2. Baixe as dependencias:
   ```bash
   flutter pub get
   ```
3. Rode:
   ```bash
   flutter run
   ```

O app ja roda **sem backend** (`ApiConstants.useMock = true`, em
`lib/core/constants/api_constants.dart`). Para apontar ao backend Smart HAS real,
coloque `useMock = false` e ajuste `baseUrl`.

## Configurar chaves (opcional, mas recomendado para a avaliacao)
- **Google Maps**: em `android/app/src/main/AndroidManifest.xml`, troque
  `YOUR_GOOGLE_MAPS_API_KEY` pela sua chave (Google Cloud > Maps SDK for Android).
- **Firebase/FCM**: troque `android/app/google-services.json` pelo arquivo real do
  console Firebase (mesmo package `br.com.fiap.digital360`).
  Sem isso, o push fica em modo local (a notificacao simulada ainda funciona).

## Web services usados (Parte 6)
1. **Open-Meteo** (`https://api.open-meteo.com`) - clima na regiao de entrega; o
   resultado alimenta o calculo de risco logistico. Sem API key.
2. **ViaCEP** (`https://viacep.com.br`) - resolve endereco completo a partir do CEP
   para validar o destino da entrega. Sem API key.

## Notificacao push (Parte 6)
- Inicio > "Testar alerta" dispara uma notificacao local simulando aviso do sistema.
- Em "Detalhe da entrega", ao recalcular risco ALTO/CRITICO, o app dispara
  automaticamente uma notificacao de alerta.
- Com Firebase configurado, mensagens FCM recebidas com o app aberto viram notificacao.

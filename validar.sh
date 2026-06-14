#!/usr/bin/env bash
# Validacao local do projeto Flutter Digital 360.
# Requer Flutter SDK instalado e no PATH (flutter --version).
set -e
flutter pub get
flutter analyze
echo "Para rodar no emulador/dispositivo: flutter run"

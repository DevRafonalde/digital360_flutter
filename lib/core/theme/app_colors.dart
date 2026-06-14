import 'package:flutter/material.dart';

/// Paleta oficial Smart HAS / Digital 360.
/// Conceito: Logistica de Alta Precisao - Dark-first, Laranja Neon, Verde Eletrico.
/// (Espelha res/values/colors.xml do projeto Kotlin original.)
class AppColors {
  AppColors._();

  // Backgrounds
  static const background = Color(0xFF0A0E1A);
  static const backgroundElevated = Color(0xFF0F1520);
  static const surface = Color(0xFF111827);
  static const surfaceVariant = Color(0xFF1A2535);
  static const surfaceCard = Color(0xFF1E2A3A);

  // Primary - Laranja Neon (acao / CTA)
  static const primary = Color(0xFFFF6B35);
  static const primaryDark = Color(0xFFE85A24);
  static const primaryLight = Color(0xFFFF8A5B);

  // Secondary - Verde Eletrico (IA / sucesso)
  static const secondary = Color(0xFF00D9A3);
  static const secondaryDark = Color(0xFF00B085);

  // Accent - Azul Eletrico (info / links)
  static const accent = Color(0xFF4FC3F7);

  // Texto
  static const onBackground = Color(0xFFE8EDF5);
  static const onSurface = Color(0xFFB8C4D0);
  static const onSurfaceMuted = Color(0xFF6B7A8D);
  static const onPrimary = Color(0xFFFFFFFF);

  // Outline / divisores
  static const outline = Color(0xFF1E2D3D);
  static const divider = Color(0xFF1A2530);

  // Semaforo de risco (AI Logistics)
  static const riskCritical = Color(0xFFFF4757);
  static const riskHigh = Color(0xFFFF6B35);
  static const riskMedium = Color(0xFFFFD32A);
  static const riskLow = Color(0xFF00D9A3);

  // Status operacionais
  static const statusPending = Color(0xFFFFD32A);
  static const statusInTransit = Color(0xFF4FC3F7);
  static const statusDelivered = Color(0xFF00D9A3);
  static const statusDelayed = Color(0xFFFF4757);
}

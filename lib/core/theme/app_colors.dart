import 'package:flutter/material.dart';

/// Paleta oficial Smart HAS / Digital 360 - identidade "Minimal Tech".
/// Conceito: grafite/preto quase todo, um UNICO acento verde eletrico de
/// marca. Risco e status mantem rampas proprias (quente/fria) pra
/// continuarem legiveis sem reintroduzir uma segunda cor de marca.
class AppColors {
  AppColors._();

  // Backgrounds
  static const background = Color(0xFF0C0D0E);
  static const backgroundElevated = Color(0xFF101112);
  static const surface = Color(0xFF151718);
  static const surfaceVariant = Color(0xFF1B1D1F);
  static const surfaceCard = Color(0xFF1F2224);

  // Primary - unico acento de marca (verde eletrico)
  static const primary = Color(0xFF7CFF9E);
  // Tom escuro/saturado da mesma familia - usado no tema claro (texto/icone
  // sobre fundo claro E texto branco sobre preenchimento solido precisam de
  // mais contraste do que o verde neon consegue dar sozinho).
  static const primaryDark = Color(0xFF149259);
  static const primaryLight = Color(0xFFA6FFC0);

  // Compatibilidade: o sistema antigo tinha "secondary" (verde/IA) e
  // "accent" (azul/info) como cores de marca separadas. No sistema de
  // acento unico, secondary resolve pro proprio primary (era a mesma
  // familia semantica: "IA / sucesso"), e accent resolve pro azul frio de
  // "em transito" (era "info/links") - mantendo os dois symbols usados em
  // varias telas sem reintroduzir uma segunda cor de marca de verdade.
  static const secondary = primary;
  static const secondaryDark = primaryDark;
  static const accent = statusInTransit;

  // Texto
  static const onBackground = Color(0xFFEDEFF0);
  static const onSurface = Color(0xFFB9BEC2);
  static const onSurfaceMuted = Color(0xFF6E7478);
  static const onPrimary = Color(0xFF0C0D0E);

  // Outline / divisores
  static const outline = Color(0xFF26292B);
  static const divider = Color(0xFF202325);

  // Semaforo de risco (AI Logistics) - rampa quente, distinta do acento verde
  static const riskCritical = Color(0xFFFF5C5C);
  static const riskHigh = Color(0xFFFF9F40);
  static const riskMedium = Color(0xFFF5D547);
  static const riskLow = primary;

  // Status operacionais - rampa fria, so converge pro verde no "entregue"
  static const statusPending = Color(0xFFC9CDD1);
  static const statusInTransit = Color(0xFF6FB7FF);
  static const statusDelivered = primary;
  static const statusDelayed = riskCritical;
}

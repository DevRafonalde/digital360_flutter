import 'package:flutter/material.dart';

/// Chave global do Navigator - usada pra navegar a partir de codigo fora da
/// arvore de widgets (ex.: o callback de toque numa notificacao local).
final navigatorKey = GlobalKey<NavigatorState>();

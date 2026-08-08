import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:digital360_flutter/ui/widgets/risk_badge.dart';

/// Golden test do RiskBadge - so roda de forma confiavel localmente (fonte
/// e DPI variam entre maquinas/CI, o padrao da comunidade Flutter e restringir
/// golden tests a execucao local, nunca no pipeline de CI compartilhado).
void main() {
  testWidgets('RiskBadge - aparencia visual dos 4 niveis de risco', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                RiskBadge(nivel: 'BAIXO', score: 10),
                SizedBox(height: 8),
                RiskBadge(nivel: 'MEDIO', score: 40),
                SizedBox(height: 8),
                RiskBadge(nivel: 'ALTO', score: 65),
                SizedBox(height: 8),
                RiskBadge(nivel: 'CRITICO', score: 90),
              ],
            ),
          ),
        ),
      ),
    );

    await expectLater(
      find.byType(Column),
      matchesGoldenFile('goldens/risk_badge_niveis.png'),
    );
  });
}

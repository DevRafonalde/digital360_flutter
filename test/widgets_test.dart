import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:digital360_flutter/ui/widgets/risk_badge.dart';

void main() {
  Widget wrap(Widget child) => MaterialApp(home: Scaffold(body: Center(child: child)));

  testWidgets('RiskBadge mostra o nivel e o score', (tester) async {
    await tester.pumpWidget(wrap(const RiskBadge(nivel: 'ALTO', score: 87)));
    expect(find.textContaining('ALTO'), findsOneWidget);
    expect(find.textContaining('87'), findsOneWidget);
  });

  testWidgets('StatusChip traduz o status com acentuacao correta', (tester) async {
    await tester.pumpWidget(wrap(const StatusChip(status: 'EM_TRANSITO')));
    expect(find.text('EM TRÂNSITO'), findsOneWidget);
  });

  testWidgets('NivelBadge renderiza o nivel do curso com acentuacao correta', (tester) async {
    await tester.pumpWidget(wrap(const NivelBadge(nivel: 'BASICO')));
    expect(find.text('BÁSICO'), findsOneWidget);
  });

  testWidgets('RiskBadge traduz nivel MEDIO/CRITICO com acento', (tester) async {
    await tester.pumpWidget(wrap(const RiskBadge(nivel: 'CRITICO', score: 99)));
    expect(find.textContaining('CRÍTICO'), findsOneWidget);
  });
}

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

  testWidgets('StatusChip troca underline por espaco', (tester) async {
    await tester.pumpWidget(wrap(const StatusChip(status: 'EM_TRANSITO')));
    expect(find.text('EM TRANSITO'), findsOneWidget);
  });

  testWidgets('NivelBadge renderiza o nivel do curso', (tester) async {
    await tester.pumpWidget(wrap(const NivelBadge(nivel: 'BASICO')));
    expect(find.text('BASICO'), findsOneWidget);
  });
}

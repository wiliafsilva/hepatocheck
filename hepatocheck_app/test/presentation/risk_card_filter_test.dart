import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hepatocheck_app/domain/entities/risk_level.dart';
import 'package:hepatocheck_app/domain/usecases/calculate_liver_health.dart';
import 'package:hepatocheck_app/presentation/theme/app_colors.dart';
import 'package:hepatocheck_app/presentation/widgets/risk_card.dart';

import '../support/test_data.dart';

void main() {
  for (final risk in RiskLevel.values) {
    testWidgets('filtro ilustrativo apenas em risco alto: $risk', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: RiskCard(
              health: LiverHealth(
                exam: testExam(),
                fib4: 4,
                percent: 0,
                risk: risk,
                weeklyAverage: 0,
                consumptionPenalty: 0,
              ),
            ),
          ),
        ),
      );
      final filter = find.byKey(const ValueKey('high-risk-yellow-filter'));
      if (risk == RiskLevel.high) {
        expect(filter, findsOneWidget);
        expect(find.text('Risco vermelho'), findsOneWidget);
        expect(
          find.textContaining('não indica presença de icterícia'),
          findsOneWidget,
        );
        final badge = tester.widget<Text>(find.text('Risco vermelho'));
        expect(badge.style?.color, AppColors.riskRed);
      } else {
        expect(filter, findsNothing);
        expect(find.textContaining('icterícia'), findsNothing);
      }
      expect(tester.takeException(), isNull);
    });
  }
  testWidgets('sem exame não aplica filtro', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: RiskCard(health: LiverHealth.empty())),
      ),
    );
    expect(find.byType(ColorFiltered), findsNothing);
  });
}

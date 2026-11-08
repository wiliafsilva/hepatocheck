import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hepatocheck_app/presentation/screens/camouflage_calculator_screen.dart';

void main() {
  Future<void> tapKey(WidgetTester tester, String key) async {
    await tester.tap(find.bySemanticsLabel('Tecla $key'));
    await tester.pump();
  }

  testWidgets('calcula normalmente sem revelar o diário', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: CamouflageCalculatorScreen(
          onSecretCodeAttempt: (_) async => false,
        ),
      ),
    );

    for (final key in ['7', '+', '3', '=']) {
      await tapKey(tester, key);
    }

    expect(find.text('10'), findsOneWidget);
  });

  testWidgets('envia o código secreto digitado para desbloquear o diário', (
    tester,
  ) async {
    String? attempt;
    await tester.pumpWidget(
      MaterialApp(
        home: CamouflageCalculatorScreen(
          onSecretCodeAttempt: (code) async {
            attempt = code;
            return code == '2580';
          },
        ),
      ),
    );

    for (final key in ['2', '5', '8', '0']) {
      await tapKey(tester, key);
    }

    expect(attempt, '2580');
  });
}

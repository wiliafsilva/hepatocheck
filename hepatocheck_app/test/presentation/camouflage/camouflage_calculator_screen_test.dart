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

  testWidgets('mantém contraste entre teclas numéricas e operadores', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData.dark(),
        home: CamouflageCalculatorScreen(
          onSecretCodeAttempt: (_) async => false,
        ),
      ),
    );

    final numberLabel = tester.widget<Text>(find.text('7'));
    final operatorLabel = tester.widget<Text>(find.text('\u00F7'));

    expect(numberLabel.style?.color, Colors.white);
    expect(operatorLabel.style?.color, Colors.white);
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

  testWidgets('reconhece o código após uma conta anterior', (tester) async {
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

    for (final key in ['1', '2', '3', '+', '4', '2', '5', '8', '0']) {
      await tapKey(tester, key);
    }

    expect(attempt, '2580');
  });

  testWidgets('ícone apaga dígitos e AC limpa a conta', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: CamouflageCalculatorScreen(
          onSecretCodeAttempt: (_) async => false,
        ),
      ),
    );
    await tapKey(tester, '1');
    await tapKey(tester, '2');
    await tester.tap(find.byIcon(Icons.backspace_outlined));
    await tester.pump();
    expect(find.text('12'), findsNothing);
    expect(find.text('1'), findsNWidgets(2));
    await tester.tap(find.text('AC'));
    await tester.pump();
    expect(find.text('0'), findsNWidgets(2));
  });
}

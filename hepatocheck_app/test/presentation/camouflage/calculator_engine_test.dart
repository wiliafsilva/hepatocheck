import 'package:flutter_test/flutter_test.dart';
import 'package:hepatocheck_app/presentation/camouflage/calculator_engine.dart';

void main() {
  group('CalculatorEngine', () {
    test('calcula uma operação básica', () {
      final calculator = CalculatorEngine();

      for (final key in ['7', '+', '3', '=']) {
        calculator.press(key);
      }

      expect(calculator.display, '10');
    });

    test('mostra erro ao dividir por zero', () {
      final calculator = CalculatorEngine();

      for (final key in ['9', '÷', '0', '=']) {
        calculator.press(key);
      }

      expect(calculator.display, 'Erro');
    });

    test('limpa a operação atual', () {
      final calculator = CalculatorEngine();

      for (final key in ['4', '2', 'C']) {
        calculator.press(key);
      }

      expect(calculator.display, '0');
    });
  });
}

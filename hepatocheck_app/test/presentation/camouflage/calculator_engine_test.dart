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

    final cases = <String, (List<String>, String)>{
      'porcentagem dentro de parênteses': (
        ['2', '×', '()', '2', '0', '0', '+', '1', '0', '%', '='],
        '440',
      ),
      'precedência de multiplicação': (['2', '+', '3', '×', '4', '='], '14'),
      'parênteses explícitos': (
        ['2', '×', '()', '3', '+', '4', '()', '='],
        '14',
      ),
      'multiplicação implícita e fechamento automático': (
        ['2', '()', '3', '+', '4', '='],
        '14',
      ),
      'grupos aninhados': (['()', '2', '+', '()', '3', '×', '4', '='], '14'),
      'subtração e divisão da esquerda para direita': (
        ['8', '÷', '2', '×', '3', '−', '1', '='],
        '11',
      ),
      'continua com resultado': (['2', '+', '3', '=', '×', '4', '='], '20'),
      'troca sinal do segundo operando': (['5', '+', '±', '2', '='], '3'),
      'troca sinal antes de digitar': (['±', '2'], '-2'),
      'porcentagem isolada': (['5', '0', '%'], '0,5'),
      'soma porcentagem relativa': (
        ['2', '0', '0', '+', '1', '0', '%', '='],
        '220',
      ),
      'subtrai porcentagem relativa': (
        ['2', '0', '0', '−', '1', '0', '%', '='],
        '180',
      ),
      'multiplica porcentagem': (
        ['2', '0', '0', '×', '1', '0', '%', '='],
        '20',
      ),
      'continua depois da porcentagem': (
        ['2', '0', '0', '+', '1', '0', '%', '+', '5', '='],
        '225',
      ),
      'substitui operador': (['8', '+', '×', '2', '='], '16'),
      'aceita uma vírgula por número': (
        ['1', ',', '2', ',', '3', '+', '0', ',', '7', '7', '='],
        '2',
      ),
      'apaga um dígito': (['1', '2', '3', '⌫'], '12'),
      'apaga número negativo por completo': (['±', '2', '⌫'], '0'),
      'AC limpa operação pendente': (['9', '+', '2', 'C', '3', '='], '3'),
      'mantém erro ao pressionar operador': (['9', '÷', '0', '=', '+'], 'Erro'),
      'permite digitar após erro': (
        ['9', '÷', '0', '=', '2', '+', '3', '='],
        '5',
      ),
      'preserva números pequenos': (
        ['1', '÷', '1', '0', '0', '0', '0', '0', '0', '0', '0', '0', '='],
        '1e-9',
      ),
      'ignora tecla vazia': (['2', '', '+', '3', '='], '5'),
    };
    for (final entry in cases.entries) {
      test(entry.key, () {
        final calculator = CalculatorEngine();
        for (final key in entry.value.$1) {
          calculator.press(key);
        }
        expect(calculator.display, entry.value.$2);
      });
    }
  });
}

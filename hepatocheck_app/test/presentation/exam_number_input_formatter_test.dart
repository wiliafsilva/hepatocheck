import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hepatocheck_app/presentation/input/exam_number_input_formatter.dart';

TextEditingValue _type(
  ExamNumberInputFormatter formatter,
  String text, {
  String old = '',
  int? cursor,
}) {
  return formatter.formatEditUpdate(
    TextEditingValue(
      text: old,
      selection: TextSelection.collapsed(offset: old.length),
    ),
    TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: cursor ?? text.length),
    ),
  );
}

void main() {
  const enzyme = ExamNumberInputFormatter(maxIntegerDigits: 4);
  const age = ExamNumberInputFormatter(maxIntegerDigits: 3, decimal: false);
  const platelets = ExamNumberInputFormatter(maxIntegerDigits: 6);

  group('Só números', () {
    test('remove letras, espaços e símbolos', () {
      expect(_type(enzyme, '3a5 U/L').text, '35');
      expect(_type(enzyme, '-35').text, '35');
      expect(_type(age, '45 anos').text, '45');
    });

    test('a idade não aceita separador decimal', () {
      expect(_type(age, '45,5').text, '455');
      expect(_type(age, '4.5').text, '45');
    });

    test('campo vazio continua vazio', () {
      expect(_type(enzyme, '').text, '');
      expect(_type(enzyme, 'abc').text, '');
    });
  });

  group('Separador decimal', () {
    test('ponto vira vírgula', () {
      expect(_type(enzyme, '35.5').text, '35,5');
    });

    test('mantém só o primeiro separador', () {
      expect(_type(enzyme, '35,5,1').text, '35,51');
      expect(_type(enzyme, '1.234,5').text, '1,23');
    });

    test('limita a 2 casas decimais', () {
      expect(_type(enzyme, '35,567').text, '35,56');
    });

    test('separador no início ganha o zero', () {
      expect(_type(enzyme, ',5').text, '0,5');
      expect(_type(enzyme, '.').text, '0,');
    });

    test('remove zeros à esquerda', () {
      expect(_type(enzyme, '007').text, '7');
      expect(_type(enzyme, '00').text, '0');
      expect(_type(enzyme, '0,5').text, '0,5');
      expect(_type(enzyme, '00,5').text, '0,5');
    });
  });

  group('Limite de dígitos inteiros', () {
    test('recusa a edição que passa do limite', () {
      expect(_type(age, '1234', old: '123').text, '123');
      expect(_type(enzyme, '12345', old: '1234').text, '1234');
    });

    test('plaquetas aceitam o valor em /mm³ para a sugestão de conversão', () {
      expect(_type(platelets, '250000').text, '250000');
      expect(_type(platelets, '2500000', old: '250000').text, '250000');
    });
  });

  group('Cursor', () {
    test('fica no lugar certo depois de remover caracteres', () {
      final value = _type(enzyme, '3x5', cursor: 2);

      expect(value.text, '35');
      expect(value.selection.extentOffset, 1);
    });

    test('acompanha a troca de ponto por vírgula no meio do texto', () {
      final value = _type(enzyme, '3.55', old: '355', cursor: 2);

      expect(value.text, '3,55');
      expect(value.selection.extentOffset, 2);
    });
  });
}

import 'package:flutter_test/flutter_test.dart';
import 'package:hepatocheck_app/domain/usecases/validate_exam_input.dart';

void main() {
  const validate = ValidateExamInput();
  final now = DateTime(2026, 11, 7, 15, 30);
  final today = DateTime(2026, 11, 7);

  ExamInputValidation run({
    String age = '45',
    String ast = '35',
    String alt = '36',
    String platelets = '181',
    DateTime? examDate,
    bool withoutDate = false,
  }) {
    return validate(
      age: age,
      ast: ast,
      alt: alt,
      platelets: platelets,
      examDate: withoutDate ? null : (examDate ?? today),
      now: now,
    );
  }

  group('Entradas válidas', () {
    test('aceita o exemplo do protótipo', () {
      final result = run();

      expect(result.isValid, isTrue);
      expect(result.age, 45);
      expect(result.ast, 35);
      expect(result.alt, 36);
      expect(result.platelets, 181);
      expect(result.examDate, today);
      expect(result.ageOutsideValidatedRange, isFalse);
    });

    test('aceita vírgula ou ponto como separador decimal', () {
      final result = run(ast: '35,5', alt: '36.2', platelets: ' 181,0 ');

      expect(result.isValid, isTrue);
      expect(result.ast, 35.5);
      expect(result.alt, 36.2);
      expect(result.platelets, 181);
    });

    test('aceita idade fora de 35 a 65, mas sinaliza o aviso', () {
      final result = run(age: '30');

      expect(result.isValid, isTrue);
      expect(result.ageOutsideValidatedRange, isTrue);
    });
  });

  group('Entradas inconsistentes', () {
    test('recusa campos vazios e indica cada um', () {
      final result = run(age: '', ast: '  ', alt: '', platelets: '');

      expect(result.isValid, isFalse);
      expect(
        result.errors.keys,
        containsAll(<ExamField>[
          ExamField.age,
          ExamField.ast,
          ExamField.alt,
          ExamField.platelets,
        ]),
      );
      expect(result.errors[ExamField.ast], ValidateExamInput.emptyMessage);
    });

    test('recusa zero e números negativos', () {
      final result = run(ast: '0', alt: '-5');

      expect(
        result.errors[ExamField.ast],
        ValidateExamInput.notPositiveMessage,
      );
      expect(
        result.errors[ExamField.alt],
        ValidateExamInput.notPositiveMessage,
      );
      expect(result.errors.containsKey(ExamField.age), isFalse);
    });

    test('recusa texto que não é número', () {
      final result = run(ast: 'abc', platelets: '18a');

      expect(result.errors[ExamField.ast], ValidateExamInput.notNumericMessage);
      expect(
        result.errors[ExamField.platelets],
        ValidateExamInput.notNumericMessage,
      );
    });

    test('recusa vírgula e ponto misturados', () {
      final result = run(platelets: '1.250,5');

      expect(
        result.errors[ExamField.platelets],
        ValidateExamInput.mixedSeparatorsMessage,
      );
    });

    test('recusa idade fora de 18 a 120 ou com casas decimais', () {
      expect(
        run(age: '17').errors[ExamField.age],
        ValidateExamInput.ageRangeMessage,
      );
      expect(
        run(age: '121').errors[ExamField.age],
        ValidateExamInput.ageRangeMessage,
      );
      expect(
        run(age: '45,5').errors[ExamField.age],
        ValidateExamInput.ageNotIntegerMessage,
      );
      expect(run(age: '18').isValid, isTrue);
      expect(run(age: '120').isValid, isTrue);
    });

    test('recusa TGO e TGP fora de 1 a 5000 U/L', () {
      final result = run(ast: '5001', alt: '0,5');

      expect(
        result.errors[ExamField.ast],
        ValidateExamInput.enzymeRangeMessage,
      );
      expect(
        result.errors[ExamField.alt],
        ValidateExamInput.enzymeRangeMessage,
      );
      expect(run(ast: '5000', alt: '1').isValid, isTrue);
    });

    test('sugere a conversão quando as plaquetas parecem estar em /mm³', () {
      final result = run(platelets: '250000');

      expect(result.isValid, isFalse);
      expect(result.platelets, isNull);
      expect(result.plateletSuggestion, 250);
      expect(result.errors[ExamField.platelets], contains('Use 250'));
    });

    test('recusa plaquetas fora de 1 a 1000 sem conversão possível', () {
      final result = run(platelets: '5000000');

      expect(
        result.errors[ExamField.platelets],
        ValidateExamInput.plateletRangeMessage,
      );
      expect(result.plateletSuggestion, isNull);
      expect(
        run(platelets: '0,5').errors[ExamField.platelets],
        ValidateExamInput.plateletRangeMessage,
      );
    });

    test('recusa data do exame no futuro ou ausente', () {
      expect(
        run(examDate: DateTime(2026, 11, 8)).errors[ExamField.examDate],
        ValidateExamInput.dateFutureMessage,
      );
      expect(
        run(withoutDate: true).errors[ExamField.examDate],
        ValidateExamInput.dateMissingMessage,
      );
      expect(run(examDate: DateTime(2026, 11, 7, 23, 59)).isValid, isTrue);
    });
  });
}

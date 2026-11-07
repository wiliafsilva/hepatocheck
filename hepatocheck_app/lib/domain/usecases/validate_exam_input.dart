import 'calculate_fib4.dart';

enum ExamField { age, examDate, ast, alt, platelets }

class ExamInputValidation {
  const ExamInputValidation({
    required this.errors,
    this.age,
    this.examDate,
    this.ast,
    this.alt,
    this.platelets,
    this.plateletSuggestion,
  });

  final Map<ExamField, String> errors;
  final int? age;
  final DateTime? examDate;
  final double? ast;
  final double? alt;
  final double? platelets;
  final double? plateletSuggestion;

  bool get isValid => errors.isEmpty;

  bool get ageOutsideValidatedRange =>
      age != null && CalculateFib4.isAgeOutsideValidatedRange(age!);
}

class ValidateExamInput {
  const ValidateExamInput();

  static const minAge = 18;
  static const maxAge = 120;
  static const minEnzyme = 1.0;
  static const maxEnzyme = 5000.0;
  static const minPlatelets = 1.0;
  static const maxPlatelets = 1000.0;

  static const emptyMessage = 'Preencha este campo.';
  static const mixedSeparatorsMessage =
      'Use vírgula ou ponto para os decimais, não os dois.';
  static const notNumericMessage = 'Digite apenas números.';
  static const notPositiveMessage = 'O valor precisa ser maior que zero.';
  static const ageNotIntegerMessage = 'Informe a idade em anos inteiros.';
  static const ageRangeMessage = 'A idade precisa estar entre 18 e 120 anos.';
  static const enzymeRangeMessage =
      'Valor fora de 1 a 5000 U/L. Confira se houve erro de digitação.';
  static const plateletRangeMessage =
      'As plaquetas precisam estar entre 1 e 1000 ×10³/mm³.';
  static const dateMissingMessage = 'Informe a data do exame.';
  static const dateFutureMessage = 'A data do exame não pode estar no futuro.';

  static final _numberPattern = RegExp(r'^-?\d+(\.\d+)?$');

  ExamInputValidation call({
    required String age,
    required String ast,
    required String alt,
    required String platelets,
    required DateTime? examDate,
    DateTime? now,
  }) {
    final errors = <ExamField, String>{};

    final ageValue = _parse(age, ExamField.age, errors);
    int? parsedAge;
    if (ageValue != null) {
      if (ageValue != ageValue.roundToDouble()) {
        errors[ExamField.age] = ageNotIntegerMessage;
      } else if (ageValue < minAge || ageValue > maxAge) {
        errors[ExamField.age] = ageRangeMessage;
      } else {
        parsedAge = ageValue.toInt();
      }
    }

    final astValue = _parseEnzyme(ast, ExamField.ast, errors);
    final altValue = _parseEnzyme(alt, ExamField.alt, errors);

    double? plateletsValue = _parse(platelets, ExamField.platelets, errors);
    double? suggestion;
    if (plateletsValue != null &&
        (plateletsValue < minPlatelets || plateletsValue > maxPlatelets)) {
      final converted = plateletsValue / 1000;
      if (plateletsValue > maxPlatelets &&
          converted >= minPlatelets &&
          converted <= maxPlatelets) {
        suggestion = converted;
        errors[ExamField.platelets] =
            'Parece que o valor está em /mm³. Use ${_format(converted)} '
            '(×10³/mm³).';
      } else {
        errors[ExamField.platelets] = plateletRangeMessage;
      }
      plateletsValue = null;
    }

    DateTime? parsedDate;
    if (examDate == null) {
      errors[ExamField.examDate] = dateMissingMessage;
    } else {
      final reference = now ?? DateTime.now();
      final today = DateTime(reference.year, reference.month, reference.day);
      final day = DateTime(examDate.year, examDate.month, examDate.day);
      if (day.isAfter(today)) {
        errors[ExamField.examDate] = dateFutureMessage;
      } else {
        parsedDate = day;
      }
    }

    return ExamInputValidation(
      errors: errors,
      age: parsedAge,
      examDate: parsedDate,
      ast: astValue,
      alt: altValue,
      platelets: plateletsValue,
      plateletSuggestion: suggestion,
    );
  }

  double? _parseEnzyme(
    String raw,
    ExamField field,
    Map<ExamField, String> errors,
  ) {
    final value = _parse(raw, field, errors);
    if (value == null) return null;
    if (value < minEnzyme || value > maxEnzyme) {
      errors[field] = enzymeRangeMessage;
      return null;
    }
    return value;
  }

  double? _parse(String raw, ExamField field, Map<ExamField, String> errors) {
    final text = raw.trim();
    if (text.isEmpty) {
      errors[field] = emptyMessage;
      return null;
    }
    if (text.contains(',') && text.contains('.')) {
      errors[field] = mixedSeparatorsMessage;
      return null;
    }
    final normalized = text.replaceAll(',', '.');
    if (!_numberPattern.hasMatch(normalized)) {
      errors[field] = notNumericMessage;
      return null;
    }
    final value = double.parse(normalized);
    if (value <= 0) {
      errors[field] = notPositiveMessage;
      return null;
    }
    return value;
  }

  static String _format(double value) {
    if (value == value.roundToDouble()) return value.toInt().toString();
    return value
        .toStringAsFixed(2)
        .replaceFirst(RegExp(r'0+$'), '')
        .replaceAll('.', ',');
  }
}

import 'package:flutter_test/flutter_test.dart';
import 'package:hepatocheck_app/domain/entities/lab_exam.dart';
import 'package:hepatocheck_app/domain/entities/risk_level.dart';
import 'package:hepatocheck_app/domain/usecases/calculate_fib4.dart';
import 'package:hepatocheck_app/domain/usecases/classify_risk.dart';

LabExam _exam({
  int age = 45,
  double ast = 35,
  double alt = 36,
  double platelets = 181,
}) {
  final date = DateTime(2026, 9, 12);
  return LabExam(
    id: 'exame-1',
    examDate: date,
    age: age,
    ast: ast,
    alt: alt,
    platelets: platelets,
    createdAt: date,
    updatedAt: date,
  );
}

void main() {
  const calculate = CalculateFib4();

  group('Cálculo do FIB-4', () {
    test('calcula o exemplo do protótipo: 1,45 e risco intermediário', () {
      final result = calculate(_exam());

      expect(result.examId, 'exame-1');
      expect(result.score, closeTo(1.4503, 0.0001));
      expect(result.riskLevel, RiskLevel.intermediate);
      expect(result.ageOutsideValidatedRange, isFalse);
    });

    test('aplica a fórmula (idade × TGO) / (plaquetas × √TGP)', () {
      final score = CalculateFib4.score(
        age: 50,
        ast: 40,
        alt: 25,
        platelets: 200,
      );

      expect(score, closeTo(2.0, 0.0001));
    });

    test('recusa valores zero ou negativos', () {
      expect(
        () => CalculateFib4.score(age: 45, ast: 0, alt: 36, platelets: 181),
        throwsArgumentError,
      );
      expect(
        () => CalculateFib4.score(age: 45, ast: 35, alt: 36, platelets: -1),
        throwsArgumentError,
      );
    });
  });

  group('Faixas de risco do FIB-4', () {
    test('abaixo de 1,30 é risco baixo', () {
      expect(CalculateFib4.riskFor(score: 1.29, age: 45), RiskLevel.low);
    });

    test('1,30 e 2,67 são risco intermediário', () {
      expect(
        CalculateFib4.riskFor(score: 1.30, age: 45),
        RiskLevel.intermediate,
      );
      expect(
        CalculateFib4.riskFor(score: 2.67, age: 45),
        RiskLevel.intermediate,
      );
    });

    test('acima de 2,67 é risco alto', () {
      expect(CalculateFib4.riskFor(score: 2.68, age: 45), RiskLevel.high);
    });

    test('a partir de 65 anos o corte do risco baixo passa para 2,0', () {
      expect(CalculateFib4.riskFor(score: 1.9, age: 65), RiskLevel.low);
      expect(
        CalculateFib4.riskFor(score: 1.9, age: 64),
        RiskLevel.intermediate,
      );
      expect(
        CalculateFib4.riskFor(score: 2.0, age: 70),
        RiskLevel.intermediate,
      );
    });

    test('avisa quando a idade está fora de 35 a 65 anos', () {
      expect(calculate(_exam(age: 34)).ageOutsideValidatedRange, isTrue);
      expect(calculate(_exam(age: 35)).ageOutsideValidatedRange, isFalse);
      expect(calculate(_exam(age: 65)).ageOutsideValidatedRange, isFalse);
      expect(calculate(_exam(age: 66)).ageOutsideValidatedRange, isTrue);
    });
  });

  group('Classificação Verde, Amarelo e Vermelho', () {
    const classify = ClassifyRisk();

    test('sem consumo ou sem limite, vale só o FIB-4', () {
      expect(classify(fib4Risk: RiskLevel.low), RiskLevel.low);
      expect(
        classify(fib4Risk: RiskLevel.low, weeklyStandardDrinks: 30),
        RiskLevel.low,
      );
      expect(
        classify(fib4Risk: RiskLevel.intermediate, weeklyDrinkLimit: 7),
        RiskLevel.intermediate,
      );
    });

    test('consumo dentro do limite mantém o nível', () {
      expect(
        classify(
          fib4Risk: RiskLevel.low,
          weeklyStandardDrinks: 7,
          weeklyDrinkLimit: 7,
        ),
        RiskLevel.low,
      );
    });

    test('consumo acima do limite sobe um nível', () {
      expect(
        classify(
          fib4Risk: RiskLevel.low,
          weeklyStandardDrinks: 8,
          weeklyDrinkLimit: 7,
        ),
        RiskLevel.intermediate,
      );
      expect(
        classify(
          fib4Risk: RiskLevel.intermediate,
          weeklyStandardDrinks: 10.5,
          weeklyDrinkLimit: 10,
        ),
        RiskLevel.high,
      );
    });

    test('risco alto continua alto mesmo acima do limite', () {
      expect(
        classify(
          fib4Risk: RiskLevel.high,
          weeklyStandardDrinks: 20,
          weeklyDrinkLimit: 5,
        ),
        RiskLevel.high,
      );
    });
  });
}

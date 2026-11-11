import 'package:flutter_test/flutter_test.dart';
import 'package:hepatocheck_app/domain/entities/drink_entry.dart';
import 'package:hepatocheck_app/domain/entities/lab_exam.dart';
import 'package:hepatocheck_app/domain/entities/risk_level.dart';
import 'package:hepatocheck_app/domain/usecases/calculate_liver_health.dart';

void main() {
  const useCase = CalculateLiverHealth();
  final now = DateTime(2026, 11, 11, 12);

  LabExam exam({
    String id = 'e1',
    DateTime? date,
    int age = 45,
    double ast = 30,
    double alt = 36,
    double platelets = 250,
  }) => LabExam(
    id: id,
    date: date ?? DateTime(2026, 11, 1),
    age: age,
    ast: ast,
    alt: alt,
    platelets: platelets,
  );

  DrinkEntry drink(double amount, {int daysAgo = 1}) => DrinkEntry(
    id: 'd$amount$daysAgo',
    dateTime: now.subtract(Duration(days: daysAgo)),
    standardDrinks: amount,
  );

  test('sem exame, não há medidor nem risco', () {
    final result = useCase(exams: [], drinks: [drink(3)], now: now);
    expect(result.hasExam, isFalse);
    expect(result.percent, isNull);
    expect(result.risk, isNull);
  });

  test('FIB-4 de 0,90 gera medidor de cerca de 72% e risco baixo', () {
    // (45 x 30) / (250 x raiz(36)) = 0,90 -> 100 x (1 - 0,90 / 3,25)
    final result = useCase(exams: [exam()], drinks: [], now: now);
    expect(result.exam!.fib4, closeTo(0.9, 1e-9));
    expect(result.percent, closeTo(72.31, 0.01));
    expect(result.risk, RiskLevel.low);
  });

  test('FIB-4 de 3,25 ou mais zera o medidor e é risco alto', () {
    final result = useCase(
      exams: [exam(ast: 100, alt: 25, platelets: 100)],
      drinks: [],
      now: now,
    );
    expect(result.percent, 0);
    expect(result.risk, RiskLevel.high);
  });

  test('usa o exame mais recente', () {
    final old = exam(
      id: 'old',
      date: DateTime(2026, 1, 1),
      ast: 100,
      alt: 25,
      platelets: 100,
    );
    final recent = exam(id: 'new');
    final result = useCase(exams: [recent, old], drinks: [], now: now);
    expect(result.exam!.id, 'new');
  });

  test('consumo até o limite semanal não desconta nada', () {
    // 28 drinques em 4 semanas = 7 por semana
    final result = useCase(exams: [exam()], drinks: [drink(28)], now: now);
    expect(result.weeklyAverage, 7);
    expect(result.consumptionPenalty, 0);
  });

  test('consumo acima do limite desconta até 15 pontos', () {
    final base = useCase(exams: [exam()], drinks: [], now: now).percent!;
    // 42 em 4 semanas = 10,5 por semana -> excesso de 3,5 -> 7,5 pontos
    final some = useCase(exams: [exam()], drinks: [drink(42)], now: now);
    expect(some.consumptionPenalty, closeTo(7.5, 1e-9));
    expect(some.percent, closeTo(base - 7.5, 1e-9));

    final lots = useCase(exams: [exam()], drinks: [drink(400)], now: now);
    expect(lots.consumptionPenalty, 15);
    expect(lots.percent, closeTo(base - 15, 1e-9));
  });

  test('registros com mais de 4 semanas ou no futuro não contam', () {
    final result = useCase(
      exams: [exam()],
      drinks: [drink(50, daysAgo: 29), drink(50, daysAgo: -1)],
      now: now,
    );
    expect(result.weeklyAverage, 0);
  });

  test('o desconto não muda a cor, que segue só o FIB-4', () {
    final result = useCase(exams: [exam()], drinks: [drink(400)], now: now);
    expect(result.risk, RiskLevel.low);
  });

  group('RiskLevel.fromFib4', () {
    test('limites da faixa para menos de 65 anos', () {
      expect(RiskLevel.fromFib4(1.29, age: 50), RiskLevel.low);
      expect(RiskLevel.fromFib4(1.30, age: 50), RiskLevel.intermediate);
      expect(RiskLevel.fromFib4(2.67, age: 50), RiskLevel.intermediate);
      expect(RiskLevel.fromFib4(2.68, age: 50), RiskLevel.high);
    });

    test('a partir de 65 anos o limite de risco baixo é 2,0', () {
      expect(RiskLevel.fromFib4(1.8, age: 65), RiskLevel.low);
      expect(RiskLevel.fromFib4(2.0, age: 65), RiskLevel.intermediate);
    });
  });
}

import 'package:flutter_test/flutter_test.dart';
import 'package:hepatocheck_app/domain/entities/lab_exam.dart';
import 'package:hepatocheck_app/domain/usecases/summarize_exam_history.dart';

LabExam _exam(String id, DateTime date, {double ast = 35}) {
  return LabExam(
    id: id,
    examDate: date,
    age: 45,
    ast: ast,
    alt: 36,
    platelets: 181,
    createdAt: date,
    updatedAt: date,
  );
}

void main() {
  const summarize = SummarizeExamHistory();
  final today = DateTime(2026, 11, 10, 15, 30);

  test('sem exames não há resumo', () {
    expect(summarize(const [], today: today), isNull);
  });

  test('compara o exame mais antigo com o mais recente', () {
    final summary = summarize([
      _exam('meio', DateTime(2026, 6, 1), ast: 40),
      _exam('recente', DateTime(2026, 10, 31), ast: 30),
      _exam('antigo', DateTime(2026, 1, 15), ast: 45),
    ], today: today)!;

    expect(summary.examCount, 3);
    expect(summary.first.examId, 'antigo');
    expect(summary.latest.examId, 'recente');
    expect(
      summary.delta,
      closeTo(summary.latest.score - summary.first.score, 0.005),
    );
    expect(summary.trend, Fib4Trend.improved);
    expect(summary.daysSinceLatest, 10);
  });

  test('aumento do FIB-4 indica piora', () {
    final summary = summarize([
      _exam('a', DateTime(2026, 1, 1), ast: 30),
      _exam('b', DateTime(2026, 5, 1), ast: 50),
    ], today: today)!;

    expect(summary.delta, greaterThan(0));
    expect(summary.trend, Fib4Trend.worsened);
  });

  test('variação menor que 0,01 é estável', () {
    expect(SummarizeExamHistory.trendFor(0), Fib4Trend.stable);
    expect(SummarizeExamHistory.trendFor(0.009), Fib4Trend.stable);
    expect(SummarizeExamHistory.trendFor(-0.01), Fib4Trend.improved);
    expect(SummarizeExamHistory.trendFor(0.01), Fib4Trend.worsened);
  });

  test('exame de hoje conta zero dias', () {
    final summary = summarize([
      _exam('hoje', DateTime(2026, 11, 10)),
    ], today: today)!;

    expect(summary.examCount, 1);
    expect(summary.daysSinceLatest, 0);
    expect(summary.trend, Fib4Trend.stable);
  });
}

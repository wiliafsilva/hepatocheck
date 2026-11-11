import '../entities/fib4_result.dart';
import '../entities/lab_exam.dart';
import 'calculate_fib4.dart';

enum Fib4Trend { improved, worsened, stable }

class ExamHistorySummary {
  const ExamHistorySummary({
    required this.examCount,
    required this.first,
    required this.latest,
    required this.firstDate,
    required this.latestDate,
    required this.delta,
    required this.trend,
    required this.daysSinceLatest,
  });

  final int examCount;
  final Fib4Result first;
  final Fib4Result latest;
  final DateTime firstDate;
  final DateTime latestDate;
  final double delta;
  final Fib4Trend trend;
  final int daysSinceLatest;
}

class SummarizeExamHistory {
  const SummarizeExamHistory([this._calculate = const CalculateFib4()]);

  static const stableThreshold = 0.01;

  final CalculateFib4 _calculate;

  ExamHistorySummary? call(List<LabExam> exams, {required DateTime today}) {
    if (exams.isEmpty) return null;

    final sorted = [...exams]
      ..sort((a, b) {
        final byDate = a.examDate.compareTo(b.examDate);
        if (byDate != 0) return byDate;
        return a.createdAt.compareTo(b.createdAt);
      });
    final firstExam = sorted.first;
    final latestExam = sorted.last;
    final first = _calculate(firstExam);
    final latest = _calculate(latestExam);
    final delta = double.parse((latest.score - first.score).toStringAsFixed(2));

    return ExamHistorySummary(
      examCount: exams.length,
      first: first,
      latest: latest,
      firstDate: firstExam.examDate,
      latestDate: latestExam.examDate,
      delta: delta,
      trend: trendFor(delta),
      daysSinceLatest: _daysBetween(latestExam.examDate, today),
    );
  }

  static Fib4Trend trendFor(double delta) {
    if (delta.abs() < stableThreshold) return Fib4Trend.stable;
    return delta < 0 ? Fib4Trend.improved : Fib4Trend.worsened;
  }

  static int _daysBetween(DateTime from, DateTime to) {
    final start = DateTime.utc(from.year, from.month, from.day);
    final end = DateTime.utc(to.year, to.month, to.day);
    final days = end.difference(start).inDays;
    return days < 0 ? 0 : days;
  }
}

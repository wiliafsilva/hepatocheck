import '../entities/drink_entry.dart';
import '../entities/lab_exam.dart';
import '../entities/reduction_goal.dart';
import 'assess_current_risk.dart';
import 'build_exam_evolution.dart';
import 'convert_to_standard_drinks.dart';
import 'summarize_exam_history.dart';

class ConsultationSummary {
  const ConsultationSummary({
    required this.risk,
    required this.recentExams,
    required this.windowStart,
    required this.windowDays,
    required this.weeklyAverage,
    required this.alcoholFreeDays,
    required this.hasDiary,
  });

  final CurrentRisk? risk;
  final List<ExamPoint> recentExams;
  final DateTime windowStart;
  final int windowDays;
  final double weeklyAverage;
  final int alcoholFreeDays;
  final bool hasDiary;

  double? get recentDelta {
    if (recentExams.length < 2) return null;
    final delta = recentExams.last.fib4.score - recentExams.first.fib4.score;
    return double.parse(delta.toStringAsFixed(2));
  }

  Fib4Trend? get recentTrend {
    final delta = recentDelta;
    return delta == null ? null : SummarizeExamHistory.trendFor(delta);
  }
}

class BuildConsultationSummary {
  const BuildConsultationSummary({
    this.assessRisk = const AssessCurrentRisk(),
    this.buildEvolution = const BuildExamEvolution(),
    this.convert = const ConvertToStandardDrinks(),
  });

  static const windowDays = 28;
  static const recentExamCount = 3;

  final AssessCurrentRisk assessRisk;
  final BuildExamEvolution buildEvolution;
  final ConvertToStandardDrinks convert;

  ConsultationSummary call({
    required List<LabExam> exams,
    required List<DrinkEntry> drinks,
    required List<ReductionGoal> goals,
    required DateTime today,
  }) {
    final end = DateTime(today.year, today.month, today.day + 1);
    final start = DateTime(today.year, today.month, today.day + 1 - windowDays);
    final inWindow = drinks
        .where(
          (entry) =>
              !entry.consumedAt.isBefore(start) &&
              entry.consumedAt.isBefore(end),
        )
        .toList();
    final drinkingDays = {
      for (final entry in inWindow)
        if (convert.ofEntry(entry) > 0)
          DateTime(
            entry.consumedAt.year,
            entry.consumedAt.month,
            entry.consumedAt.day,
          ),
    };
    final evolution = buildEvolution(exams);

    return ConsultationSummary(
      risk: assessRisk(
        exams: exams,
        drinks: drinks,
        goals: goals,
        today: today,
      ),
      recentExams: evolution.length <= recentExamCount
          ? evolution
          : evolution.sublist(evolution.length - recentExamCount),
      windowStart: start,
      windowDays: windowDays,
      weeklyAverage: convert.total(inWindow) / (windowDays / 7),
      alcoholFreeDays: windowDays - drinkingDays.length,
      hasDiary: drinks.isNotEmpty,
    );
  }
}

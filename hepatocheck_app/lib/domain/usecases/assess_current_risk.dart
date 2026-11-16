import '../entities/drink_entry.dart';
import '../entities/fib4_result.dart';
import '../entities/lab_exam.dart';
import '../entities/reduction_goal.dart';
import '../entities/report_period.dart';
import '../entities/risk_level.dart';
import 'calculate_fib4.dart';
import 'classify_risk.dart';
import 'convert_to_standard_drinks.dart';
import 'evaluate_goal.dart';

class CurrentRisk {
  const CurrentRisk({
    required this.exam,
    required this.fib4,
    required this.level,
    required this.weeklyStandardDrinks,
    required this.weeklyLimit,
  });

  final LabExam exam;
  final Fib4Result fib4;
  final RiskLevel level;
  final double weeklyStandardDrinks;
  final int? weeklyLimit;

  bool get raisedByConsumption => level != fib4.riskLevel;
}

class AssessCurrentRisk {
  const AssessCurrentRisk({
    this.calculate = const CalculateFib4(),
    this.classify = const ClassifyRisk(),
    this.convert = const ConvertToStandardDrinks(),
  });

  final CalculateFib4 calculate;
  final ClassifyRisk classify;
  final ConvertToStandardDrinks convert;

  CurrentRisk? call({
    required List<LabExam> exams,
    required List<DrinkEntry> drinks,
    required List<ReductionGoal> goals,
    required DateTime today,
  }) {
    final exam = latestExam(exams);
    if (exam == null) return null;

    final fib4 = calculate(exam);
    final week = ReportPeriod.containing(today, ReportPeriodType.week);
    final weekly = convert.total(
      drinks.where((entry) => week.contains(entry.consumedAt)),
    );
    final limit = weeklyLimit(goals, week);

    return CurrentRisk(
      exam: exam,
      fib4: fib4,
      level: classify(
        fib4Risk: fib4.riskLevel,
        weeklyStandardDrinks: limit == null ? null : weekly,
        weeklyDrinkLimit: limit,
      ),
      weeklyStandardDrinks: weekly,
      weeklyLimit: limit,
    );
  }

  static LabExam? latestExam(List<LabExam> exams) {
    if (exams.isEmpty) return null;
    return exams.reduce((latest, exam) {
      final byDate = exam.examDate.compareTo(latest.examDate);
      if (byDate != 0) return byDate > 0 ? exam : latest;
      return exam.createdAt.isAfter(latest.createdAt) ? exam : latest;
    });
  }

  static int? weeklyLimit(List<ReductionGoal> goals, ReportPeriod week) {
    final targets = goals
        .where(
          (goal) =>
              goal.active &&
              goal.type == GoalType.maxDrinksPerWeek &&
              goalApplies(goal, week),
        )
        .map((goal) => goal.target);
    if (targets.isEmpty) return null;
    return targets.reduce((a, b) => a < b ? a : b);
  }
}

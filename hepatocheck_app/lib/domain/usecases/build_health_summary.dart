import '../entities/consumption_report.dart';
import '../entities/drink_entry.dart';
import '../entities/lab_exam.dart';
import '../entities/reduction_goal.dart';
import '../entities/report_period.dart';
import 'assess_current_risk.dart';
import 'build_consumption_report.dart';
import 'build_exam_evolution.dart';
import 'evaluate_goal.dart';
import 'summarize_exam_history.dart';

class HealthSummary {
  const HealthSummary({
    required this.generatedAt,
    required this.risk,
    required this.evolution,
    required this.examHistory,
    required this.report,
    required this.goals,
  });

  final DateTime generatedAt;
  final CurrentRisk? risk;
  final List<ExamPoint> evolution;
  final ExamHistorySummary? examHistory;
  final ConsumptionReport report;
  final List<GoalProgress> goals;

  ReportPeriod get period => report.period;
}

class BuildHealthSummary {
  const BuildHealthSummary({
    this.assessRisk = const AssessCurrentRisk(),
    this.buildEvolution = const BuildExamEvolution(),
    this.summarizeHistory = const SummarizeExamHistory(),
    this.buildReport = const BuildConsumptionReport(),
    this.evaluateGoal = const EvaluateGoal(),
  });

  final AssessCurrentRisk assessRisk;
  final BuildExamEvolution buildEvolution;
  final SummarizeExamHistory summarizeHistory;
  final BuildConsumptionReport buildReport;
  final EvaluateGoal evaluateGoal;

  HealthSummary call({
    required List<LabExam> exams,
    required List<DrinkEntry> drinks,
    required List<ReductionGoal> goals,
    required ReportPeriod period,
    required DateTime now,
  }) {
    return HealthSummary(
      generatedAt: now,
      risk: assessRisk(exams: exams, drinks: drinks, goals: goals, today: now),
      evolution: buildEvolution(exams),
      examHistory: summarizeHistory(exams, today: now),
      report: buildReport(drinks, period, today: now),
      goals: goalProgressIn(goals, drinks, period, now),
    );
  }

  List<GoalProgress> goalProgressIn(
    List<ReductionGoal> goals,
    List<DrinkEntry> drinks,
    ReportPeriod period,
    DateTime now,
  ) {
    final progress = <GoalProgress>[];
    var week = ReportPeriod.containing(period.start, ReportPeriodType.week);
    while (week.start.isBefore(period.end)) {
      for (final goal in goals.where(
        (goal) => goal.active && goalApplies(goal, week),
      )) {
        progress.add(evaluateGoal(goal, drinks, week, now));
      }
      week = week.next;
    }
    return progress;
  }
}

import '../entities/drink_entry.dart';
import '../entities/reduction_goal.dart';
import '../entities/report_period.dart';
import 'convert_to_standard_drinks.dart';

enum GoalStatus { upcoming, progressing, nearLimit, exceeded, achieved }

class GoalProgress {
  const GoalProgress({
    required this.goal,
    required this.week,
    required this.value,
    required this.status,
  });
  final ReductionGoal goal;
  final ReportPeriod week;
  final double value;
  final GoalStatus status;

  double get fraction {
    if (goal.target == 0) {
      return status == GoalStatus.achieved || value > 0 ? 1 : 0;
    }
    return (value / goal.target).clamp(0, 1);
  }

  String get feedback => switch (status) {
    GoalStatus.upcoming => 'A meta começa nesta semana.',
    GoalStatus.achieved =>
      'Meta cumprida! Continue acompanhando seu progresso.',
    GoalStatus.nearLimit =>
      goal.type == GoalType.maxDrinksPerWeek
          ? 'Você está perto do limite que definiu.'
          : 'Atenção aos dias restantes para alcançar sua meta.',
    GoalStatus.exceeded =>
      goal.type == GoalType.maxDrinksPerWeek
          ? 'O limite foi ultrapassado. Você pode rever seu planejamento.'
          : 'A meta não pode mais ser atingida nesta semana. Planeje a próxima.',
    GoalStatus.progressing => 'Meta em acompanhamento.',
  };
}

class EvaluateGoal {
  const EvaluateGoal();

  GoalProgress call(
    ReductionGoal goal,
    List<DrinkEntry> entries,
    ReportPeriod week,
    DateTime now,
  ) {
    final today = DateTime(now.year, now.month, now.day);
    final drinkingDays = <DateTime>{};
    var total = 0.0;
    for (final entry in entries) {
      if (!week.contains(entry.consumedAt) || entry.consumedAt.isAfter(now)) {
        continue;
      }
      final drinks = const ConvertToStandardDrinks().ofEntry(entry);
      total += drinks;
      if (drinks > 0) {
        final date = entry.consumedAt;
        drinkingDays.add(DateTime(date.year, date.month, date.day));
      }
    }
    // Só dias encerrados podem contar como dias sem consumo.
    final completed = week.days().where((day) => day.isBefore(today)).toList();
    final freeDays = completed
        .where((day) => !drinkingDays.contains(day))
        .length;
    final remaining = week
        .days()
        .where((day) => !day.isBefore(today) && !drinkingDays.contains(day))
        .length;
    final maxDrinks = goal.type == GoalType.maxDrinksPerWeek;
    final value = maxDrinks ? total : freeDays.toDouble();
    GoalStatus status;
    if (week.start.isAfter(now)) {
      status = GoalStatus.upcoming;
    } else if (maxDrinks) {
      if (total > goal.target + 1e-9) {
        status = GoalStatus.exceeded;
      } else if (!now.isBefore(week.end)) {
        status = GoalStatus.achieved;
      } else if (goal.target > 0 && total >= goal.target * 0.8) {
        status = GoalStatus.nearLimit;
      } else {
        status = GoalStatus.progressing;
      }
    } else if (freeDays >= goal.target) {
      status = GoalStatus.achieved;
    } else if (freeDays + remaining < goal.target) {
      status = GoalStatus.exceeded;
    } else if (freeDays + remaining == goal.target) {
      status = GoalStatus.nearLimit;
    } else {
      status = GoalStatus.progressing;
    }
    return GoalProgress(goal: goal, week: week, value: value, status: status);
  }
}

bool goalApplies(ReductionGoal goal, ReportPeriod week) =>
    !goal.startDate.isAfter(week.start) &&
    (goal.endDate == null || goal.endDate!.isAfter(week.start));

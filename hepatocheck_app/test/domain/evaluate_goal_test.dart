import 'package:flutter_test/flutter_test.dart';
import 'package:hepatocheck_app/domain/entities/follow_up_settings.dart';
import 'package:hepatocheck_app/domain/entities/reduction_goal.dart';
import 'package:hepatocheck_app/domain/entities/report_period.dart';
import 'package:hepatocheck_app/domain/usecases/evaluate_goal.dart';
import 'package:hepatocheck_app/domain/usecases/build_follow_up_messages.dart';

import '../support/test_data.dart';

void main() {
  final monday = DateTime(2026, 11, 9);
  final week = ReportPeriod.containing(monday, ReportPeriodType.week);
  ReductionGoal goal(GoalType type, int target) => ReductionGoal(
    id: 'goal',
    type: type,
    target: target,
    startDate: monday,
    active: true,
    createdAt: monday,
    updatedAt: monday,
  );
  const evaluate = EvaluateGoal();

  test('avisa perto de 80%, acima do limite e após edição do diário', () {
    final target = goal(GoalType.maxDrinksPerWeek, 10);
    // Cada entrada contém exatamente um drinque padrão.
    final drink = testDrink(1, monday).copyWith(quantity: 8);
    expect(
      evaluate(target, [drink], week, DateTime(2026, 11, 10)).status,
      GoalStatus.nearLimit,
    );
    expect(
      evaluate(
        target,
        [drink.copyWith(quantity: 11)],
        week,
        DateTime(2026, 11, 10),
      ).status,
      GoalStatus.exceeded,
    );
    expect(
      evaluate(target, [], week, DateTime(2026, 11, 10)).status,
      GoalStatus.progressing,
    );
  });

  test('limite só é cumprido após encerrar a semana', () {
    final target = goal(GoalType.maxDrinksPerWeek, 0);
    expect(evaluate(target, [], week, monday).status, GoalStatus.progressing);
    expect(evaluate(target, [], week, week.end).status, GoalStatus.achieved);
  });

  test('dias sem consumo excluem hoje e dias futuros', () {
    final target = goal(GoalType.alcoholFreeDaysPerWeek, 3);
    expect(evaluate(target, [], week, monday).value, 0);
    expect(evaluate(target, [], week, DateTime(2026, 11, 12)).value, 3);
    expect(
      evaluate(target, [], week, DateTime(2026, 11, 12)).status,
      GoalStatus.achieved,
    );
    final entry = testDrink(1, DateTime(2026, 11, 10));
    expect(evaluate(target, [entry], week, DateTime(2026, 11, 12)).value, 2);
  });

  test('identifica quando não restam dias suficientes', () {
    final target = goal(GoalType.alcoholFreeDaysPerWeek, 7);
    final entry = testDrink(1, monday);
    expect(
      evaluate(target, [entry], week, DateTime(2026, 11, 10)).status,
      GoalStatus.exceeded,
    );
  });

  test('não usa registros de outras semanas', () {
    final target = goal(GoalType.maxDrinksPerWeek, 1);
    final entry = testDrink(1, monday.subtract(const Duration(days: 1)));
    expect(evaluate(target, [entry], week, monday).value, 0);
  });

  test('feedback inclui semana encerrada e personaliza dica pela ausência de registros', () {
    final target = goal(GoalType.maxDrinksPerWeek, 2);
    final messages = buildFollowUpMessages(
      [],
      [],
      [target],
      week.end,
      trackingStartedAt: monday,
    );
    expect(messages.any((m) => m.key.endsWith('-achieved')), isTrue);
    expect(
      messages.firstWhere((m) => m.key == 'education').body,
      contains('Dias sem registros'),
    );
  });

  test('serialização preserva todos os campos da meta', () {
    final target = goal(GoalType.maxDrinksPerWeek, 0);
    expect(ReductionGoal.fromJson(target.toJson()).toJson(), target.toJson());
  });

  test('seção 5.6 prioriza consumo acima da meta', () {
    final messages = buildFollowUpMessages(
      [testDrink(3, DateTime(2026, 11, 10))],
      [],
      [goal(GoalType.maxDrinksPerWeek, 2)],
      DateTime(2026, 11, 11),
    );
    expect(
      messages.firstWhere((m) => m.key == 'education').body,
      contains('passou da sua meta'),
    );
  });
  test('seção 5.6 apresenta educação para risco amarelo ou vermelho', () {
    final messages = buildFollowUpMessages(
      [],
      [testExam(ast: 90, platelets: 200)],
      [],
      DateTime(2026, 11, 14),
    );
    expect(
      messages.firstWhere((m) => m.key == 'risk-info').body,
      contains('DHGNA'),
    );
  });
  test('intervalos por faixa respeitam o último dia do mês', () {
    const settings = FollowUpSettings(
      lowRiskMonths: 1,
      intermediateRiskMonths: 2,
      highRiskMonths: 3,
    );
    final exam = testExam(examDate: DateTime(2026, 1, 31));
    expect(nextExamDate(settings, [exam]), DateTime(2026, 2, 28, 19));
    expect(
      nextExamDate(settings, [exam.copyWith(ast: 50)]),
      DateTime(2026, 3, 31, 19),
    );
    expect(
      nextExamDate(settings, [exam.copyWith(ast: 100, platelets: 100)]),
      DateTime(2026, 4, 30, 19),
    );
    expect(nextExamDate(const FollowUpSettings(), [exam]), isNull);
  });
  test('exame vencido gera mensagem e novo exame recalcula prazo', () {
    const settings = FollowUpSettings(lowRiskMonths: 1);
    final exam = testExam(examDate: DateTime(2026, 9, 1));
    final messages = buildFollowUpMessages(
      [],
      [exam],
      [],
      DateTime(2026, 11, 14),
      settings: settings,
    );
    expect(
      messages.firstWhere((m) => m.key == 'exam-info').body,
      contains('já passou'),
    );
    expect(
      nextExamDate(settings, [
        exam,
        testExam(examDate: DateTime(2026, 11, 14)),
      ]),
      DateTime(2026, 12, 14, 19),
    );
  });

  test(
    'instalação nova aguarda três dias e registro retroativo renova o prazo',
    () {
      final now = DateTime(2026, 11, 14);
      final fresh = buildFollowUpMessages(
        [],
        [],
        [],
        now,
        trackingStartedAt: now,
      );
      expect(fresh.any((m) => m.key == 'registration-info'), isFalse);
      final inactive = buildFollowUpMessages(
        [],
        [],
        [],
        now,
        trackingStartedAt: DateTime(2026, 11, 11),
      );
      expect(inactive.any((m) => m.key == 'registration-info'), isTrue);
      final entry = testDrink(
        1,
        DateTime(2026, 11, 1),
      ).copyWith(updatedAt: now);
      final updated = buildFollowUpMessages([entry], [], [], now);
      expect(updated.any((m) => m.key == 'registration-info'), isFalse);
    },
  );
}

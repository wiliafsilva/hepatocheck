import '../entities/drink_entry.dart';
import '../entities/lab_exam.dart';
import '../entities/reduction_goal.dart';
import '../entities/report_period.dart';
import '../entities/follow_up_settings.dart';
import '../entities/risk_level.dart';
import 'calculate_fib4.dart';
import 'evaluate_goal.dart';

class FollowUpMessage {
  const FollowUpMessage(this.key, this.title, this.body);
  final String key, title, body;
}

List<FollowUpMessage> buildFollowUpMessages(
  List<DrinkEntry> drinks,
  List<LabExam> exams,
  List<ReductionGoal> goals,
  DateTime now, {
  FollowUpSettings settings = const FollowUpSettings(),
  DateTime? trackingStartedAt,
}) {
  final week = ReportPeriod.containing(now, ReportPeriodType.week);
  final messages = <FollowUpMessage>[];
  var exceeded = false;
  var achieved = false;
  for (final currentWeek in [week, week.previous]) {
    for (final goal in goals.where(
      (goal) => goal.active && goalApplies(goal, currentWeek),
    )) {
      final progress = const EvaluateGoal()(goal, drinks, currentWeek, now);
      exceeded =
          exceeded ||
          (currentWeek == week && progress.status == GoalStatus.exceeded);
      achieved = achieved || progress.status == GoalStatus.achieved;
      messages.add(
        FollowUpMessage(
          'goal-${goal.id}-${currentWeek.start.toIso8601String()}-${progress.status.name}',
          goal.type == GoalType.maxDrinksPerWeek
              ? 'Sua meta de redução'
              : 'Seus dias sem consumo',
          'Semana de ${currentWeek.start.day}/${currentWeek.start.month}: ${progress.feedback}',
        ),
      );
    }
  }
  final latest = latestExam(exams);
  final risk = latest == null ? null : const CalculateFib4()(latest).riskLevel;
  final due = nextExamDate(settings, exams);
  final overdue = due != null && due.isBefore(now);
  final lastDrink = drinks.isEmpty
      ? trackingStartedAt ?? now
      : drinks.map((e) => e.updatedAt).reduce((a, b) => a.isAfter(b) ? a : b);
  final today = DateTime(now.year, now.month, now.day);
  final daysWithoutRecord = DateTime.utc(today.year, today.month, today.day)
      .difference(DateTime.utc(lastDrink.year, lastDrink.month, lastDrink.day))
      .inDays;
  // Fonte: https://www.niddk.nih.gov/health-information/liver-disease/nafld-nash/symptoms-causes
  const riskMessage =
      'A DHGNA envolve acúmulo de gordura no fígado e pode não apresentar sintomas. Seu resultado de triagem está na faixa amarela ou vermelha: converse com um profissional de saúde sobre o acompanhamento. O app não faz diagnóstico.';
  String education;
  if (exceeded) {
    education = 'Você passou da sua meta desta semana. Que tal planejar um dia sem álcool amanhã?';
  } else if (risk == RiskLevel.intermediate || risk == RiskLevel.high) {
    education = riskMessage;
  } else if (overdue && latest != null) {
    var months =
        (now.year - latest.examDate.year) * 12 +
        now.month -
        latest.examDate.month;
    if (now.day < latest.examDate.day) months--;
    final age = months > 0 ? 'há $months mês(es)' : 'neste mês';
    education =
        'Seu último exame foi $age e a data de acompanhamento configurada chegou. Converse com seu médico sobre repetir.';
  } else if (daysWithoutRecord >= 3) {
    education = 'Lembrete rápido: registre seu consumo e mantenha o diário atualizado. Dias sem registros não confirmam ausência de consumo.';
  } else if (achieved) {
    education = 'Meta da semana cumprida. Continue acompanhando seu progresso!';
  } else {
    education = 'Consulte suas metas e confira as quantidades registradas para acompanhar sua evolução.';
  }
  messages.add(
    FollowUpMessage('education', 'Dica para seu acompanhamento', education),
  );
  if (risk == RiskLevel.intermediate || risk == RiskLevel.high) {
    messages.add(
      const FollowUpMessage(
        'risk-info',
        'Quando procurar acompanhamento',
        riskMessage,
      ),
    );
  }
  if (daysWithoutRecord >= 3) {
    messages.add(
      const FollowUpMessage(
        'registration-info',
        'Atualize seus registros',
        'Você está há pelo menos três dias sem registrar. Reserve um momento para atualizar o diário.',
      ),
    );
  }
  if (latest == null) {
    messages.add(
      const FollowUpMessage(
        'exam-info',
        'Organize seus exames',
        'Combine com seu profissional de saúde a próxima avaliação e configure um lembrete.',
      ),
    );
  } else {
    messages.add(
      FollowUpMessage(
        'exam-info',
        overdue
            ? 'Reveja o acompanhamento dos exames'
            : 'Acompanhe seus exames',
        overdue
            ? 'A data de acompanhamento configurada já passou. Converse com seu médico sobre repetir os exames.'
            : due == null
            ? 'Informe a data ou o intervalo em meses orientado pelo profissional para sua faixa de risco.'
            : 'Próximo acompanhamento configurado para ${due.day}/${due.month}/${due.year}.',
      ),
    );
  }
  return messages;
}

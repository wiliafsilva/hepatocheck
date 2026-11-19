import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/usecases/build_consultation_summary.dart';
import 'drink_providers.dart';
import 'exam_providers.dart';
import 'goal_providers.dart';
import 'report_providers.dart';
import 'risk_providers.dart';

final buildConsultationSummaryProvider = Provider(
  (ref) => BuildConsultationSummary(
    assessRisk: ref.watch(assessCurrentRiskProvider),
    buildEvolution: ref.watch(buildExamEvolutionProvider),
    convert: ref.watch(convertToStandardDrinksProvider),
  ),
);

final consultationSummaryProvider = Provider<ConsultationSummary>(
  (ref) => ref.watch(buildConsultationSummaryProvider)(
    exams: ref.watch(examsProvider),
    drinks: ref.watch(drinksProvider),
    goals: ref.watch(goalsProvider),
    today: ref.watch(todayProvider),
  ),
);

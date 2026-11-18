import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/usecases/assess_current_risk.dart';
import '../../domain/usecases/build_exam_evolution.dart';
import 'drink_providers.dart';
import 'exam_providers.dart';
import 'goal_providers.dart';
import 'report_providers.dart';

final assessCurrentRiskProvider = Provider(
  (ref) => AssessCurrentRisk(
    calculate: ref.watch(calculateFib4Provider),
    classify: ref.watch(classifyRiskProvider),
    convert: ref.watch(convertToStandardDrinksProvider),
  ),
);

final currentRiskProvider = Provider<CurrentRisk?>(
  (ref) => ref.watch(assessCurrentRiskProvider)(
    exams: ref.watch(examsProvider),
    drinks: ref.watch(drinksProvider),
    goals: ref.watch(goalsProvider),
    today: ref.watch(todayProvider),
  ),
);

final buildExamEvolutionProvider = Provider(
  (ref) => BuildExamEvolution(ref.watch(calculateFib4Provider)),
);

final examEvolutionProvider = Provider<List<ExamPoint>>(
  (ref) => ref.watch(buildExamEvolutionProvider)(ref.watch(examsProvider)),
);

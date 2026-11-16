import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/usecases/build_risk_evolution.dart';
import 'drink_providers.dart';
import 'exam_providers.dart';
import 'liver_health_provider.dart';

final buildRiskEvolutionProvider = Provider(
  (ref) => BuildRiskEvolution(ref.watch(calculateLiverHealthProvider)),
);

/// Evolução do FIB-4 e do medidor do fígado, um ponto por exame.
final riskEvolutionProvider = Provider<List<RiskEvolutionPoint>>(
  (ref) => ref.watch(buildRiskEvolutionProvider)(
    exams: ref.watch(examsProvider),
    drinks: ref.watch(drinksProvider),
  ),
);

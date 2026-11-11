import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/usecases/calculate_liver_health.dart';
import 'drink_providers.dart';
import 'exam_providers.dart';

/// Relógio injetável, para os testes fixarem a data.
final clockProvider = Provider<DateTime Function()>((ref) => DateTime.now);

final calculateLiverHealthProvider = Provider(
  (ref) => CalculateLiverHealth(
    converter: ref.watch(convertToStandardDrinksProvider),
  ),
);

/// Medidor do fígado, recalculado sempre que um exame ou um registro do
/// diário muda.
final liverHealthProvider = Provider<LiverHealth>((ref) {
  final exams = ref.watch(examsProvider);
  final drinks = ref.watch(drinksProvider);
  final now = ref.watch(clockProvider)();
  return ref.watch(calculateLiverHealthProvider)(
    exams: exams,
    drinks: drinks,
    now: now,
  );
});

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/usecases/calculate_liver_health.dart';
import 'repository_providers.dart';

/// Relógio injetável, para os testes fixarem a data.
final clockProvider = Provider<DateTime Function()>((ref) => DateTime.now);

/// Medidor do fígado, recalculado sempre que um exame ou um registro do
/// diário muda.
final liverHealthProvider = Provider<LiverHealth>((ref) {
  final exams = ref.watch(examsProvider).value ?? const [];
  final drinks = ref.watch(drinksProvider).value ?? const [];
  final now = ref.watch(clockProvider)();
  return const CalculateLiverHealth()(exams: exams, drinks: drinks, now: now);
});

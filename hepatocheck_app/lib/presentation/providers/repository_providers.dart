import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/repositories/in_memory_drink_repository.dart';
import '../../data/repositories/in_memory_exam_repository.dart';
import '../../domain/entities/drink_entry.dart';
import '../../domain/entities/lab_exam.dart';
import '../../domain/repositories/drink_repository.dart';
import '../../domain/repositories/exam_repository.dart';

/// Repositórios usados pelas telas. Hoje em memória; quando o Hive com AES
/// estiver pronto, basta trocar a implementação aqui.
final examRepositoryProvider = Provider<ExamRepository>(
  (ref) => InMemoryExamRepository(),
);

final drinkRepositoryProvider = Provider<DrinkRepository>(
  (ref) => InMemoryDrinkRepository(),
);

final examsProvider = StreamProvider<List<LabExam>>(
  (ref) => ref.watch(examRepositoryProvider).watchAll(),
);

final drinksProvider = StreamProvider<List<DrinkEntry>>(
  (ref) => ref.watch(drinkRepositoryProvider).watchAll(),
);

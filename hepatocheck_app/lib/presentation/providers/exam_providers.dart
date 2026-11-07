import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/datasources/local/hive_database.dart';
import '../../data/repositories/hive_exam_repository.dart';
import '../../domain/entities/lab_exam.dart';
import '../../domain/repositories/exam_repository.dart';
import '../../domain/usecases/calculate_fib4.dart';
import '../../domain/usecases/classify_risk.dart';
import '../../domain/usecases/validate_exam_input.dart';

final examRepositoryProvider = Provider<ExamRepository>(
  (ref) => HiveExamRepository(HiveDatabase.exams),
);

final calculateFib4Provider = Provider((ref) => const CalculateFib4());

final classifyRiskProvider = Provider((ref) => const ClassifyRisk());

final validateExamInputProvider = Provider((ref) => const ValidateExamInput());

final examsProvider = NotifierProvider<ExamsNotifier, List<LabExam>>(
  ExamsNotifier.new,
);

class ExamsNotifier extends Notifier<List<LabExam>> {
  @override
  List<LabExam> build() => ref.read(examRepositoryProvider).getAll();

  Future<void> save(LabExam exam) async {
    final repository = ref.read(examRepositoryProvider);
    await repository.save(exam);
    state = repository.getAll();
  }

  Future<void> delete(String id) async {
    final repository = ref.read(examRepositoryProvider);
    await repository.delete(id);
    state = repository.getAll();
  }
}

import 'package:hive_ce/hive.dart';

import '../../domain/entities/lab_exam.dart';
import '../../domain/repositories/exam_repository.dart';

class HiveExamRepository implements ExamRepository {
  HiveExamRepository(this._box);

  final Box<LabExam> _box;

  @override
  List<LabExam> getAll() {
    final exams = _box.values.toList()
      ..sort((a, b) {
        final byDate = b.examDate.compareTo(a.examDate);
        if (byDate != 0) return byDate;
        return b.createdAt.compareTo(a.createdAt);
      });
    return exams;
  }

  @override
  LabExam? getById(String id) => _box.get(id);

  @override
  Future<void> save(LabExam exam) => _box.put(exam.id, exam);

  @override
  Future<void> delete(String id) => _box.delete(id);
}

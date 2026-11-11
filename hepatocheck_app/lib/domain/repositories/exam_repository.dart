import '../entities/lab_exam.dart';

abstract interface class ExamRepository {
  List<LabExam> getAll();

  LabExam? getById(String id);

  Future<void> save(LabExam exam);

  Future<void> delete(String id);
}

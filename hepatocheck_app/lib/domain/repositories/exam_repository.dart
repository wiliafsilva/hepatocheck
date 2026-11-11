import '../entities/lab_exam.dart';

/// Contrato do repositório de exames; a implementação fica na camada data.
abstract class ExamRepository {
  /// Emite a lista atual e uma nova lista a cada alteração.
  Stream<List<LabExam>> watchAll();

  /// Cria o exame ou substitui o que tem o mesmo id.
  Future<void> save(LabExam exam);

  Future<void> delete(String id);
}

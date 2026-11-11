import 'dart:async';

import '../../domain/entities/lab_exam.dart';
import '../../domain/repositories/exam_repository.dart';

/// Repositório em memória, usado até o Hive com AES ser ligado.
class InMemoryExamRepository implements ExamRepository {
  final _items = <String, LabExam>{};
  final _changes = StreamController<void>.broadcast();

  List<LabExam> _snapshot() => List.unmodifiable(_items.values);

  @override
  Stream<List<LabExam>> watchAll() {
    late final StreamController<List<LabExam>> controller;
    StreamSubscription<void>? sub;
    controller = StreamController<List<LabExam>>(
      onListen: () {
        controller.add(_snapshot());
        sub = _changes.stream.listen((_) => controller.add(_snapshot()));
      },
      onCancel: () => sub?.cancel(),
    );
    return controller.stream;
  }

  @override
  Future<void> save(LabExam exam) async {
    _items[exam.id] = exam;
    _changes.add(null);
  }

  @override
  Future<void> delete(String id) async {
    _items.remove(id);
    _changes.add(null);
  }
}

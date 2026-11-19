import 'package:flutter_test/flutter_test.dart';
import 'package:hepatocheck_app/domain/entities/lab_exam.dart';
import 'package:hepatocheck_app/domain/usecases/check_exam_age_consistency.dart';

LabExam exam(String id, DateTime date, int age) => LabExam(
  id: id,
  examDate: date,
  age: age,
  ast: 30,
  alt: 30,
  platelets: 200,
  createdAt: date,
  updatedAt: date,
);

void main() {
  const check = CheckExamAgeConsistency();
  final history = [
    exam('marco', DateTime(2026, 3, 10), 55),
    exam('junho', DateTime(2026, 6, 10), 55),
    exam('novembro', DateTime(2026, 11, 10), 56),
  ];

  test('aceita idades coerentes de um mesmo paciente', () {
    expect(
      check(examDate: DateTime(2026, 11, 18), age: 56, exams: history),
      isNull,
    );
    expect(
      check(examDate: DateTime(2027, 9, 1), age: 57, exams: history),
      isNull,
    );
  });

  test('aponta idade menor que a de um exame anterior', () {
    final conflict = check(
      examDate: DateTime(2026, 11, 18),
      age: 45,
      exams: history,
    );

    expect(conflict, isNotNull);
    expect(conflict!.exam.id, 'novembro');
    expect((conflict.minAge, conflict.maxAge), (56, 57));
  });

  test('aponta idade maior que a possível num exame antigo', () {
    final conflict = check(
      examDate: DateTime(2025, 12, 1),
      age: 58,
      exams: history,
    );

    expect(conflict, isNotNull);
    expect(conflict!.exam.id, 'marco');
    expect((conflict.minAge, conflict.maxAge), (54, 55));
  });

  test('ignora o próprio exame ao editar', () {
    expect(
      check(
        examDate: DateTime(2026, 11, 10),
        age: 56,
        exams: history,
        ignoreId: 'novembro',
      ),
      isNull,
    );
  });

  test('no mesmo dia do ano a diferença é exata', () {
    expect(
      CheckExamAgeConsistency.expectedAgeRange(
        knownDate: DateTime(2025, 3, 10),
        knownAge: 54,
        targetDate: DateTime(2026, 3, 10),
      ),
      (55, 55),
    );
    expect(
      CheckExamAgeConsistency.expectedAgeRange(
        knownDate: DateTime(2026, 3, 10),
        knownAge: 55,
        targetDate: DateTime(2026, 3, 10),
      ),
      (55, 55),
    );
  });
}

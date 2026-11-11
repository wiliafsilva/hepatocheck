import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hepatocheck_app/domain/entities/lab_exam.dart';
import 'package:hepatocheck_app/domain/repositories/exam_repository.dart';
import 'package:hepatocheck_app/presentation/providers/exam_providers.dart';
import 'package:hepatocheck_app/presentation/screens/exams_screen.dart';

class _EmptyExamRepository implements ExamRepository {
  @override
  List<LabExam> getAll() => const [];

  @override
  LabExam? getById(String id) => null;

  @override
  Future<void> save(LabExam exam) async {}

  @override
  Future<void> delete(String id) async {}
}

void main() {
  testWidgets('os campos do exame aceitam apenas números', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          examRepositoryProvider.overrideWithValue(_EmptyExamRepository()),
        ],
        child: const MaterialApp(home: Scaffold(body: ExamsScreen())),
      ),
    );

    final fields = find.byType(TextField);
    expect(fields, findsNWidgets(4));

    await tester.enterText(fields.at(0), '4a5');
    await tester.enterText(fields.at(1), '35.5x');
    await tester.enterText(fields.at(2), 'abc36');
    await tester.enterText(fields.at(3), '181 mil');
    await tester.pump();

    String textOf(int index) =>
        tester.widget<TextField>(fields.at(index)).controller!.text;

    expect(textOf(0), '45');
    expect(textOf(1), '35,5');
    expect(textOf(2), '36');
    expect(textOf(3), '181');
  });
}

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

class _FlakyExamRepository implements ExamRepository {
  final Map<String, LabExam> stored = {};
  var failNextSave = true;

  @override
  List<LabExam> getAll() =>
      stored.values.toList()..sort((a, b) => b.examDate.compareTo(a.examDate));

  @override
  LabExam? getById(String id) => stored[id];

  @override
  Future<void> save(LabExam exam) async {
    stored[exam.id] = exam;
    if (failNextSave) {
      failNextSave = false;
      throw StateError('fila indisponível');
    }
  }

  @override
  Future<void> delete(String id) async => stored.remove(id);
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

  testWidgets('tentar de novo após falha ao salvar não duplica o exame', (
    tester,
  ) async {
    final repository = _FlakyExamRepository();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [examRepositoryProvider.overrideWithValue(repository)],
        child: const MaterialApp(home: Scaffold(body: ExamsScreen())),
      ),
    );

    final fields = find.byType(TextField);
    await tester.enterText(fields.at(0), '45');
    await tester.enterText(fields.at(1), '35');
    await tester.enterText(fields.at(2), '36');
    await tester.enterText(fields.at(3), '181');
    await tester.tap(find.text('Calcular e salvar'));
    await tester.pumpAndSettle();

    expect(
      find.text('Não foi possível salvar o exame. Tente novamente.'),
      findsOneWidget,
    );

    await tester.tap(find.text('Calcular e salvar'));
    await tester.pumpAndSettle();

    expect(repository.stored, hasLength(1));
    expect(find.text('Exame salvo.'), findsOneWidget);
  });
}

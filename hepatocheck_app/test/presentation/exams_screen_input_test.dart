import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/intl.dart';
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

class _MemoryExamRepository implements ExamRepository {
  _MemoryExamRepository(List<LabExam> exams)
    : stored = {for (final exam in exams) exam.id: exam};

  final Map<String, LabExam> stored;

  @override
  List<LabExam> getAll() =>
      stored.values.toList()..sort((a, b) => b.examDate.compareTo(a.examDate));

  @override
  LabExam? getById(String id) => stored[id];

  @override
  Future<void> save(LabExam exam) async => stored[exam.id] = exam;

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

  testWidgets('avisa quando a idade não combina com um exame anterior', (
    tester,
  ) async {
    final previousDate = DateUtils.dateOnly(DateTime.now())
        .subtract(const Duration(days: 30));
    final repository = _MemoryExamRepository([
      LabExam(
        id: 'anterior',
        examDate: previousDate,
        age: 56,
        ast: 25,
        alt: 30,
        platelets: 250,
        createdAt: previousDate,
        updatedAt: previousDate,
      ),
    ]);
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

    expect(find.text('Confira a idade'), findsOneWidget);
    await tester.tap(find.text('Corrigir'));
    await tester.pumpAndSettle();

    expect(repository.stored, hasLength(1));
    expect(
      find.text('Idade esperada nesta data: 56 ou 57 anos.'),
      findsOneWidget,
    );

    await tester.tap(find.text('Calcular e salvar'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Salvar assim mesmo'));
    await tester.pumpAndSettle();

    expect(repository.stored, hasLength(2));
    expect(find.text('Exame salvo.'), findsOneWidget);
  });

  testWidgets('idade coerente salva sem aviso', (tester) async {
    final previousDate = DateUtils.dateOnly(DateTime.now())
        .subtract(const Duration(days: 30));
    final repository = _MemoryExamRepository([
      LabExam(
        id: 'anterior',
        examDate: previousDate,
        age: 56,
        ast: 25,
        alt: 30,
        platelets: 250,
        createdAt: previousDate,
        updatedAt: previousDate,
      ),
    ]);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [examRepositoryProvider.overrideWithValue(repository)],
        child: const MaterialApp(home: Scaffold(body: ExamsScreen())),
      ),
    );

    final fields = find.byType(TextField);
    await tester.enterText(fields.at(0), '56');
    await tester.enterText(fields.at(1), '35');
    await tester.enterText(fields.at(2), '36');
    await tester.enterText(fields.at(3), '181');
    await tester.tap(find.text('Calcular e salvar'));
    await tester.pumpAndSettle();

    expect(find.text('Confira a idade'), findsNothing);
    expect(repository.stored, hasLength(2));
  });

  testWidgets('a data do exame cabe numa linha em celular pequeno', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          examRepositoryProvider.overrideWithValue(_EmptyExamRepository()),
        ],
        child: const MaterialApp(home: Scaffold(body: ExamsScreen())),
      ),
    );

    final dateText = find.text(DateFormat('dd/MM/yyyy').format(DateTime.now()));
    final style = tester.widget<Text>(dateText).style!;
    final lineHeight = style.fontSize! * style.height!;

    expect(tester.getSize(dateText).height, lessThan(lineHeight * 1.5));
    expect(tester.takeException(), isNull);
  });
}

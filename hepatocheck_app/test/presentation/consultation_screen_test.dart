import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hepatocheck_app/domain/entities/drink_entry.dart';
import 'package:hepatocheck_app/domain/entities/lab_exam.dart';
import 'package:hepatocheck_app/domain/entities/reduction_goal.dart';
import 'package:hepatocheck_app/domain/repositories/drink_repository.dart';
import 'package:hepatocheck_app/domain/repositories/exam_repository.dart';
import 'package:hepatocheck_app/domain/repositories/goal_repository.dart';
import 'package:hepatocheck_app/presentation/providers/drink_providers.dart';
import 'package:hepatocheck_app/presentation/providers/exam_providers.dart';
import 'package:hepatocheck_app/presentation/providers/goal_providers.dart';
import 'package:hepatocheck_app/presentation/providers/report_providers.dart';
import 'package:hepatocheck_app/presentation/screens/consultation_screen.dart';

import '../support/test_data.dart';

class _Exams implements ExamRepository {
  _Exams(this.items);

  final List<LabExam> items;

  @override
  List<LabExam> getAll() => items;

  @override
  LabExam? getById(String id) => null;

  @override
  Future<void> save(LabExam exam) async {}

  @override
  Future<void> delete(String id) async {}
}

class _Drinks implements DrinkRepository {
  _Drinks(this.items);

  final List<DrinkEntry> items;

  @override
  List<DrinkEntry> getAll() => items;

  @override
  DrinkEntry? getById(String id) => null;

  @override
  Future<void> save(DrinkEntry entry) async {}

  @override
  Future<void> delete(String id) async {}
}

class _Goals implements GoalRepository {
  @override
  List<ReductionGoal> getAll() => const [];

  @override
  Future<void> save(ReductionGoal goal) async {}

  @override
  Future<void> delete(String id) async {}
}

Future<void> _pump(
  WidgetTester tester, {
  List<LabExam> exams = const [],
  List<DrinkEntry> drinks = const [],
  double textScale = 1,
}) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        clockProvider.overrideWithValue(() => DateTime(2026, 11, 18, 15)),
        examRepositoryProvider.overrideWithValue(_Exams(exams)),
        drinkRepositoryProvider.overrideWithValue(_Drinks(drinks)),
        goalRepositoryProvider.overrideWithValue(_Goals()),
      ],
      child: MaterialApp(
        home: MediaQuery(
          data: MediaQueryData(textScaler: TextScaler.linear(textScale)),
          child: Builder(
            builder: (context) => Scaffold(
              body: Center(
                child: TextButton(
                  onPressed: () => ConsultationScreen.open(context),
                  child: const Text('abrir'),
                ),
              ),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.tap(find.text('abrir'));
  await tester.pumpAndSettle();
}

final _exams = [
  testExam(id: 'a', examDate: DateTime(2026, 3, 1), ast: 45),
  testExam(id: 'b', examDate: DateTime(2026, 6, 1), ast: 40),
  testExam(id: 'c', examDate: DateTime(2026, 9, 12), ast: 35),
];

void main() {
  setUpAll(() async {
    final loader = FontLoader('Inter');
    for (final f in ['Regular', 'Medium', 'SemiBold', 'Bold']) {
      final bytes = File('assets/fonts/Inter-$f.ttf').readAsBytesSync();
      loader.addFont(Future.value(ByteData.sublistView(bytes)));
    }
    await loader.load();
  });

  testWidgets('mostra risco, exame, consumo e evolução', (tester) async {
    await _pump(
      tester,
      exams: _exams,
      drinks: [
        testDrink(12, DateTime(2026, 11, 1, 20)),
        testDrink(6, DateTime(2026, 11, 15, 20)),
      ],
    );

    expect(find.text('Modo consulta'), findsOneWidget);
    expect(find.text('VERDE'), findsOneWidget);
    expect(find.text('FIB-4 atual'), findsOneWidget);
    expect(find.text('Exame de 12/09/2026'), findsOneWidget);
    expect(find.text('4,5'), findsOneWidget);
    expect(
      find.text('Média dos últimos 28 dias · 26 dias sem álcool'),
      findsOneWidget,
    );

    await tester.scrollUntilVisible(
      find.text('Set/26'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('Mar/26'), findsOneWidget);
    expect(find.textContaining('Queda de'), findsOneWidget);
  });

  testWidgets('sem dados explica o que falta', (tester) async {
    await _pump(tester);

    expect(find.textContaining('Nenhum exame registrado'), findsOneWidget);
    expect(find.text('Nenhum registro no diário de consumo.'), findsOneWidget);
    expect(find.text('EVOLUÇÃO DO FIB-4'), findsNothing);
  });

  testWidgets('o botão de sair fecha o modo consulta', (tester) async {
    await _pump(tester, exams: _exams);
    await tester.scrollUntilVisible(
      find.text('Sair do modo consulta'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.text('Sair do modo consulta'));
    await tester.pumpAndSettle();

    expect(find.text('abrir'), findsOneWidget);
    expect(find.text('Modo consulta'), findsNothing);
  });

  testWidgets('em 360 px com fonte em 200% nada transborda', (tester) async {
    tester.view.physicalSize = const Size(360, 740);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await _pump(
      tester,
      exams: _exams,
      drinks: [testDrink(3, DateTime(2026, 11, 10))],
      textScale: 2,
    );
    await tester.scrollUntilVisible(
      find.text('Sair do modo consulta'),
      200,
      scrollable: find.byType(Scrollable).first,
    );

    expect(tester.takeException(), isNull);
  });
}

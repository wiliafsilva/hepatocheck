import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hepatocheck_app/domain/entities/drink_entry.dart';
import 'package:hepatocheck_app/domain/entities/drink_type.dart';
import 'package:hepatocheck_app/domain/entities/lab_exam.dart';
import 'package:hepatocheck_app/domain/repositories/drink_repository.dart';
import 'package:hepatocheck_app/domain/repositories/exam_repository.dart';
import 'package:hepatocheck_app/presentation/providers/drink_providers.dart';
import 'package:hepatocheck_app/presentation/providers/exam_providers.dart';
import 'package:hepatocheck_app/presentation/providers/report_providers.dart';
import 'package:hepatocheck_app/presentation/screens/report_screen.dart';

class _FakeExamRepository implements ExamRepository {
  _FakeExamRepository(this._exams);

  final List<LabExam> _exams;

  @override
  List<LabExam> getAll() => _exams;

  @override
  LabExam? getById(String id) => null;

  @override
  Future<void> save(LabExam exam) async {}

  @override
  Future<void> delete(String id) async {}
}

class _FakeDrinkRepository implements DrinkRepository {
  _FakeDrinkRepository(this._drinks);

  final List<DrinkEntry> _drinks;

  @override
  List<DrinkEntry> getAll() => _drinks;

  @override
  DrinkEntry? getById(String id) => null;

  @override
  Future<void> save(DrinkEntry entry) async {}

  @override
  Future<void> delete(String id) async {}
}

DrinkEntry _beer(DateTime consumedAt, {int quantity = 1}) => DrinkEntry(
  id: 'cerveja-${consumedAt.toIso8601String()}',
  type: DrinkType.beer,
  volumeMl: 350,
  alcoholPercent: 5,
  quantity: quantity,
  consumedAt: consumedAt,
  createdAt: consumedAt,
  updatedAt: consumedAt,
);

Future<void> _pump(
  WidgetTester tester,
  List<LabExam> exams, {
  List<DrinkEntry> drinks = const [],
}) {
  return tester.pumpWidget(
    ProviderScope(
      overrides: [
        clockProvider.overrideWithValue(() => DateTime(2026, 11, 10)),
        examRepositoryProvider.overrideWithValue(_FakeExamRepository(exams)),
        drinkRepositoryProvider.overrideWithValue(_FakeDrinkRepository(drinks)),
      ],
      child: const MaterialApp(home: Scaffold(body: ReportScreen())),
    ),
  );
}

void main() {
  testWidgets('alterna entre semana e mês e navega pelos períodos', (
    tester,
  ) async {
    await _pump(tester, const []);

    expect(find.text('09/11 a 15/11'), findsOneWidget);
    expect(
      find.text('Registre um exame na aba Exames para ver seu risco.'),
      findsOneWidget,
    );
    expect(
      find.text('Nenhum drinque registrado neste período.'),
      findsOneWidget,
    );

    await tester.tap(find.byTooltip('Período anterior'));
    await tester.pump();
    expect(find.text('02/11 a 08/11'), findsOneWidget);

    await tester.tap(find.text('Mês'));
    await tester.pump();
    expect(find.text('novembro de 2026'), findsOneWidget);

    await tester.tap(find.byTooltip('Período anterior'));
    await tester.pump();
    expect(find.text('outubro de 2026'), findsOneWidget);
  });

  testWidgets('mostra o risco do exame mais recente', (tester) async {
    final date = DateTime(2026, 9, 12);
    await _pump(tester, [
      LabExam(
        id: 'exame-1',
        examDate: date,
        age: 45,
        ast: 35,
        alt: 36,
        platelets: 181,
        createdAt: date,
        updatedAt: date,
      ),
    ]);

    expect(find.text('1,45'), findsOneWidget);
    expect(find.text('AMARELO'), findsOneWidget);
    expect(find.text('Exame de 12/09/2026'), findsOneWidget);
  });

  testWidgets('cabe em uma tela de 360 px de largura', (tester) async {
    tester.view.physicalSize = const Size(360, 740);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await _pump(tester, const []);
    await tester.scrollUntilVisible(
      find.text('Dias sem álcool'),
      200,
      scrollable: find.byType(Scrollable).first,
    );

    expect(tester.takeException(), isNull);
  });

  testWidgets('mostra o consumo do período com os dados do diário', (
    tester,
  ) async {
    await _pump(
      tester,
      const [],
      drinks: [
        _beer(DateTime(2026, 11, 3, 20)),
        _beer(DateTime(2026, 11, 9, 21), quantity: 2),
      ],
    );

    expect(find.text('Nenhum drinque registrado neste período.'), findsNothing);
    expect(find.text('2'), findsWidgets);
    expect(find.text('1 de 2'), findsOneWidget);
    expect(find.text('+1'), findsOneWidget);
    expect(find.text('100%'), findsOneWidget);

    await tester.scrollUntilVisible(
      find.text('Cerveja'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('Cerveja'), findsOneWidget);
  });
}

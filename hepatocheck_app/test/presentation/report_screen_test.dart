import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hepatocheck_app/presentation/providers/goal_providers.dart';
import 'package:hepatocheck_app/domain/repositories/goal_repository.dart';
import 'package:hepatocheck_app/domain/entities/reduction_goal.dart';
import 'package:hepatocheck_app/domain/entities/drink_entry.dart';
import 'package:hepatocheck_app/domain/entities/drink_type.dart';
import 'package:hepatocheck_app/domain/entities/lab_exam.dart';
import 'package:hepatocheck_app/domain/repositories/drink_repository.dart';
import 'package:hepatocheck_app/domain/repositories/exam_repository.dart';
import 'package:hepatocheck_app/presentation/providers/drink_providers.dart';
import 'package:hepatocheck_app/presentation/providers/exam_providers.dart';
import 'package:hepatocheck_app/presentation/providers/pdf_providers.dart';
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

LabExam _exam(String id, DateTime date, {double ast = 35, int age = 45}) =>
    LabExam(
      id: id,
      examDate: date,
      age: age,
      ast: ast,
      alt: 36,
      platelets: 181,
      createdAt: date,
      updatedAt: date,
    );

ReductionGoal _drinkLimit(int target) => ReductionGoal(
  id: 'meta-1',
  type: GoalType.maxDrinksPerWeek,
  target: target,
  startDate: DateTime(2026, 11, 2),
  active: true,
  createdAt: DateTime(2026, 11, 2),
  updatedAt: DateTime(2026, 11, 2),
);

Future<void> _pump(
  WidgetTester tester,
  List<LabExam> exams, {
  List<DrinkEntry> drinks = const [],
  List<ReductionGoal> goals = const [],
  PdfOutput? output,
  double textScale = 1,
}) {
  return tester.pumpWidget(
    ProviderScope(
      overrides: [
        goalRepositoryProvider.overrideWithValue(_FakeGoalRepository(goals)),
        clockProvider.overrideWithValue(() => DateTime(2026, 11, 10, 22)),
        examRepositoryProvider.overrideWithValue(_FakeExamRepository(exams)),
        drinkRepositoryProvider.overrideWithValue(_FakeDrinkRepository(drinks)),
        healthSummaryPdfProvider.overrideWithValue(
          (_) async => Uint8List.fromList('%PDF-teste'.codeUnits),
        ),
        if (output != null) pdfOutputProvider.overrideWithValue(output),
      ],
      child: MaterialApp(
        home: MediaQuery(
          data: MediaQueryData(textScaler: TextScaler.linear(textScale)),
          child: const Scaffold(body: ReportScreen()),
        ),
      ),
    ),
  );
}

Future<void> _scrollTo(WidgetTester tester, Finder finder) async {
  await tester.scrollUntilVisible(
    finder,
    200,
    scrollable: find.byType(Scrollable).first,
  );
  await tester.ensureVisible(finder);
  await tester.pumpAndSettle();
}

void main() {
  setUpAll(() async {
    final loader = FontLoader('Inter');
    for (final f in ['Regular', 'Medium', 'SemiBold', 'Bold']) {
      final bytes = File('assets/fonts/Inter-$f.ttf').readAsBytesSync();
      loader.addFont(Future.value(ByteData.sublistView(bytes)));
    }
    await loader.load();
  });

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

  testWidgets('avisa que a semana em andamento usa os mesmos dias', (
    tester,
  ) async {
    const note =
        'Período em andamento: comparado com os 2 primeiros dias da '
        'semana anterior, até o mesmo horário.';
    await _pump(tester, const [], drinks: [_beer(DateTime(2026, 11, 9))]);
    await _scrollTo(tester, find.text(note));

    expect(find.text(note), findsOneWidget);
  });

  testWidgets('período encerrado não mostra o aviso', (tester) async {
    await _pump(tester, const []);
    await tester.tap(find.byTooltip('Período anterior'));
    await tester.pump();

    expect(find.textContaining('Período em andamento'), findsNothing);
  });

  testWidgets('com a fonte do celular em 200% nada transborda', (tester) async {
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await _pump(
      tester,
      [_exam('a', DateTime(2026, 5, 1)), _exam('b', DateTime(2026, 9, 12))],
      drinks: [
        _beer(DateTime(2026, 11, 3, 20)),
        _beer(DateTime(2026, 11, 9, 21), quantity: 2),
      ],
      goals: [_drinkLimit(1)],
      textScale: 2,
    );
    await _scrollTo(tester, find.text('Compartilhar'));

    expect(tester.takeException(), isNull);
  });

  testWidgets('sobe o nível quando o consumo passa da meta semanal', (
    tester,
  ) async {
    final date = DateTime(2026, 10, 1);
    await _pump(
      tester,
      [
        LabExam(
          id: 'verde',
          examDate: date,
          age: 45,
          ast: 30,
          alt: 36,
          platelets: 250,
          createdAt: date,
          updatedAt: date,
        ),
      ],
      drinks: [_beer(DateTime(2026, 11, 9, 21), quantity: 3)],
      goals: [_drinkLimit(1)],
    );

    expect(find.text('AMARELO'), findsOneWidget);
    expect(find.textContaining('Nível elevado para Amarelo'), findsOneWidget);
  });

  testWidgets('dentro da meta mantém o nível do FIB-4', (tester) async {
    await _pump(
      tester,
      [_exam('a', DateTime(2026, 9, 12))],
      drinks: [_beer(DateTime(2026, 11, 9, 21))],
      goals: [_drinkLimit(5)],
    );

    expect(find.text('AMARELO'), findsOneWidget);
    expect(find.textContaining('Nível elevado'), findsNothing);
  });

  testWidgets('dashboard sem exames pede o primeiro registro', (tester) async {
    await _pump(tester, const []);

    expect(
      find.text('Registre exames na aba Exames para acompanhar a evolução.'),
      findsOneWidget,
    );
  });

  testWidgets('dashboard com um exame pede outro para comparar', (
    tester,
  ) async {
    await _pump(tester, [_exam('a', DateTime(2026, 9, 12))]);

    expect(
      find.text('Registre outro exame para ver a evolução.'),
      findsOneWidget,
    );
    expect(find.text('Evolução do FIB-4'), findsNothing);
  });

  testWidgets('dashboard com três exames mostra gráfico e tendência', (
    tester,
  ) async {
    await _pump(tester, [
      _exam('a', DateTime(2026, 3, 1), ast: 45),
      _exam('b', DateTime(2026, 6, 1), ast: 40),
      _exam('c', DateTime(2026, 9, 12)),
    ]);

    expect(find.text('Evolução do FIB-4'), findsOneWidget);
    expect(find.text('Melhorou'), findsOneWidget);
    expect(find.text('Verde < 1,30'), findsOneWidget);

    await tester.tap(find.text('Plaquetas'));
    await tester.pump();
    expect(find.text('Plaquetas (×10³/mm³)'), findsOneWidget);
  });

  testWidgets('dashboard usa o corte de 2,0 a partir de 65 anos', (
    tester,
  ) async {
    await _pump(tester, [
      _exam('a', DateTime(2026, 3, 1), age: 64),
      _exam('b', DateTime(2026, 9, 12), age: 66),
    ]);

    expect(find.text('Verde < 2,00'), findsOneWidget);
    expect(find.text('Amarelo 2,00 a 2,67'), findsOneWidget);
  });

  testWidgets('dois exames no mesmo dia pedem outro para comparar', (
    tester,
  ) async {
    await _pump(tester, [
      _exam('a', DateTime(2026, 9, 12)),
      _exam('b', DateTime(2026, 9, 12), ast: 40),
    ]);

    expect(
      find.text('Registre outro exame para ver a evolução.'),
      findsOneWidget,
    );
  });

  testWidgets('o botão Modo consulta abre o resumo para o profissional', (
    tester,
  ) async {
    await _pump(tester, [_exam('a', DateTime(2026, 9, 12))]);
    await _scrollTo(tester, find.text('Modo consulta'));

    await tester.tap(find.text('Modo consulta'));
    await tester.pumpAndSettle();

    expect(find.text('Sair do modo consulta'), findsOneWidget);
    expect(find.text('FIB-4 atual'), findsOneWidget);
  });

  testWidgets('compartilhar pede confirmação antes de enviar o PDF', (
    tester,
  ) async {
    final output = _FakePdfOutput();
    await _pump(tester, const [], output: output);
    await _scrollTo(tester, find.text('Compartilhar'));

    await tester.tap(find.text('Compartilhar'));
    await tester.pumpAndSettle();
    expect(find.text('Compartilhar o resumo?'), findsOneWidget);

    await tester.tap(find.text('Cancelar'));
    await tester.pumpAndSettle();
    expect(output.shared, isEmpty);

    await tester.tap(find.text('Compartilhar'));
    await tester.pumpAndSettle();
    await tester.tap(
      find.descendant(
        of: find.byType(AlertDialog),
        matching: find.text('Compartilhar'),
      ),
    );
    await tester.pumpAndSettle();

    expect(output.shared, ['resumo-saude-2026-11-10.pdf']);
  });

  testWidgets('visualizar abre o PDF sem pedir confirmação', (tester) async {
    final output = _FakePdfOutput();
    await _pump(tester, const [], output: output);
    await _scrollTo(tester, find.text('Visualizar / salvar'));

    await tester.tap(find.text('Visualizar / salvar'));
    await tester.pumpAndSettle();

    expect(find.text('Compartilhar o resumo?'), findsNothing);
    expect(output.previewed, ['resumo-saude-2026-11-10.pdf']);
  });
}

class _FakePdfOutput implements PdfOutput {
  final shared = <String>[];
  final previewed = <String>[];

  @override
  Future<void> preview(Uint8List bytes, String fileName) async =>
      previewed.add(fileName);

  @override
  Future<void> share(Uint8List bytes, String fileName) async =>
      shared.add(fileName);
}

class _FakeGoalRepository implements GoalRepository {
  _FakeGoalRepository(this._goals);

  final List<ReductionGoal> _goals;

  @override
  List<ReductionGoal> getAll() => _goals;
  @override
  Future<void> save(ReductionGoal goal) async {}
  @override
  Future<void> delete(String id) async {}
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hepatocheck_app/domain/repositories/local_data_eraser.dart';
import 'package:hepatocheck_app/presentation/providers/drink_providers.dart';
import 'package:hepatocheck_app/presentation/providers/exam_providers.dart';
import 'package:hepatocheck_app/presentation/providers/local_data_providers.dart';
import 'package:hepatocheck_app/presentation/theme/app_theme.dart';
import 'package:hepatocheck_app/presentation/widgets/erase_local_data_tile.dart';

import '../support/test_data.dart';

class _FakeEraser implements LocalDataEraser {
  _FakeEraser(this.drinks, this.exams);

  final MemoryDrinkRepository drinks;
  final MemoryExamRepository exams;
  var calls = 0;

  @override
  Future<void> eraseAll() async {
    calls++;
    for (final entry in drinks.getAll()) {
      await drinks.delete(entry.id);
    }
    for (final exam in exams.getAll()) {
      await exams.delete(exam.id);
    }
  }
}

void main() {
  late MemoryDrinkRepository drinks;
  late MemoryExamRepository exams;
  late _FakeEraser eraser;
  late ProviderContainer container;

  setUp(() async {
    drinks = MemoryDrinkRepository();
    exams = MemoryExamRepository();
    eraser = _FakeEraser(drinks, exams);
    await drinks.save(testDrink(2, DateTime(2026, 11, 14)));
    await exams.save(testExam());
    container = ProviderContainer(
      overrides: [
        drinkRepositoryProvider.overrideWithValue(drinks),
        examRepositoryProvider.overrideWithValue(exams),
        localDataEraserProvider.overrideWithValue(eraser),
      ],
    );
  });

  tearDown(() => container.dispose());

  Future<void> pump(WidgetTester tester) async {
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          theme: AppTheme.dark,
          home: const Scaffold(body: EraseLocalDataTile()),
        ),
      ),
    );
    expect(container.read(drinksProvider), hasLength(1));
    expect(container.read(examsProvider), hasLength(1));
  }

  testWidgets('cancelar não apaga nada', (tester) async {
    await pump(tester);

    await tester.tap(find.text('Apagar todos os dados'));
    await tester.pumpAndSettle();
    expect(find.text('Apagar todos os dados?'), findsOneWidget);

    await tester.tap(find.text('Cancelar'));
    await tester.pumpAndSettle();

    expect(eraser.calls, 0);
    expect(container.read(drinksProvider), hasLength(1));
  });

  testWidgets('confirmar apaga os dados e atualiza as telas', (tester) async {
    await pump(tester);

    await tester.tap(find.text('Apagar todos os dados'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Apagar tudo'));
    await tester.pumpAndSettle();

    expect(eraser.calls, 1);
    expect(container.read(drinksProvider), isEmpty);
    expect(container.read(examsProvider), isEmpty);
    expect(
      find.text('Todos os dados deste aparelho foram apagados.'),
      findsOneWidget,
    );
  });
}

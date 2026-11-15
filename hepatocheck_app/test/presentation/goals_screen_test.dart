import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hepatocheck_app/domain/entities/reduction_goal.dart';
import 'package:hepatocheck_app/domain/repositories/goal_repository.dart';
import 'package:hepatocheck_app/presentation/providers/goal_providers.dart';
import 'package:hepatocheck_app/presentation/providers/drink_providers.dart';
import 'package:hepatocheck_app/presentation/screens/goals_screen.dart';

import '../support/test_data.dart';

class MemoryGoalRepository implements GoalRepository {
  final items = <String, ReductionGoal>{};
  @override
  List<ReductionGoal> getAll() => items.values.toList();
  @override
  Future<void> save(ReductionGoal goal) async {
    items[goal.id] = goal;
  }

  @override
  Future<void> delete(String id) async {
    items.remove(id);
  }
}

void main() {
  testWidgets('cria, edita e exclui meta pelo fluxo normal', (tester) async {
    final repository = MemoryGoalRepository();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          goalRepositoryProvider.overrideWithValue(repository),
          drinkRepositoryProvider.overrideWithValue(MemoryDrinkRepository()),
        ],
        child: const MaterialApp(home: GoalsScreen()),
      ),
    );
    await tester.tap(find.text('Criar meta'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField), '101');
    await tester.ensureVisible(find.text('Salvar meta'));
    await tester.tap(find.text('Salvar meta'));
    await tester.pumpAndSettle();
    expect(find.text('Informe um número de 0 a 100.'), findsWidgets);
    expect(repository.getAll(), isEmpty);
    await tester.enterText(find.byType(TextFormField), '100');
    await tester.ensureVisible(find.text('Salvar meta'));
    await tester.tap(find.text('Salvar meta'));
    await tester.pumpAndSettle();
    expect(repository.getAll().single.target, 100);
    await tester.ensureVisible(find.text('Editar'));
    await tester.tap(find.text('Editar'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField), '2');
    await tester.ensureVisible(find.text('Salvar meta'));
    await tester.tap(find.text('Salvar meta'));
    await tester.pumpAndSettle();
    expect(repository.getAll().single.target, 2);
    await tester.ensureVisible(find.text('Excluir'));
    await tester.tap(find.text('Excluir'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Excluir'));
    await tester.pumpAndSettle();
    expect(repository.getAll(), isEmpty);
    expect(find.text('Você ainda não criou uma meta.'), findsOneWidget);
  });
}

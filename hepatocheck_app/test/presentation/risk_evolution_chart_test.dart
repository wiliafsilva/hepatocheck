import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hepatocheck_app/presentation/providers/drink_providers.dart';
import 'package:hepatocheck_app/presentation/providers/exam_providers.dart';
import 'package:hepatocheck_app/presentation/providers/risk_evolution_provider.dart';
import 'package:hepatocheck_app/presentation/theme/app_theme.dart';
import 'package:hepatocheck_app/presentation/widgets/risk_evolution_chart.dart';

import '../support/test_data.dart';

class _Host extends ConsumerWidget {
  const _Host();

  @override
  Widget build(BuildContext context, WidgetRef ref) => Scaffold(
    body: SingleChildScrollView(
      child: RiskEvolutionChart(points: ref.watch(riskEvolutionProvider)),
    ),
  );
}

void main() {
  Future<ProviderContainer> pump(WidgetTester tester) async {
    final container = ProviderContainer(
      overrides: [
        examRepositoryProvider.overrideWithValue(MemoryExamRepository()),
        drinkRepositoryProvider.overrideWithValue(MemoryDrinkRepository()),
      ],
    );
    addTearDown(container.dispose);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(theme: AppTheme.dark, home: const _Host()),
      ),
    );
    return container;
  }

  testWidgets('sem exames mostra o convite', (tester) async {
    await pump(tester);
    expect(find.textContaining('Registre exames'), findsOneWidget);
    expect(find.byType(LineChart), findsNothing);
  });

  testWidgets('com um exame pede outro para ver a evolução', (tester) async {
    final container = await pump(tester);
    await container.read(examsProvider.notifier).save(testExam());
    await tester.pumpAndSettle();

    expect(find.byType(LineChart), findsOneWidget);
    expect(find.text('Registre outro exame para ver a evolução.'), findsOneWidget);
  });

  testWidgets('alterna entre medidor e FIB-4 e atualiza ao salvar exame', (
    tester,
  ) async {
    final container = await pump(tester);
    final exams = container.read(examsProvider.notifier);
    await exams.save(testExam(id: 'a', examDate: DateTime(2026, 5, 1)));
    await exams.save(testExam(id: 'b', examDate: DateTime(2026, 11, 1)));
    await tester.pumpAndSettle();

    expect(find.byType(LineChart), findsOneWidget);
    expect(find.textContaining('Cada ponto é um exame'), findsOneWidget);

    await tester.tap(find.text('FIB-4'));
    await tester.pumpAndSettle();
    expect(find.byType(LineChart), findsOneWidget);

    await tester.tap(find.text('Medidor'));
    await tester.pumpAndSettle();
    expect(find.byType(LineChart), findsOneWidget);
  });
}

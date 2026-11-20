import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hepatocheck_app/presentation/providers/liver_health_provider.dart';
import 'package:hepatocheck_app/presentation/providers/report_providers.dart'
    as report;
import 'package:hepatocheck_app/presentation/providers/drink_providers.dart';
import 'package:hepatocheck_app/presentation/providers/exam_providers.dart';
import 'package:hepatocheck_app/presentation/providers/goal_providers.dart';
import 'package:hepatocheck_app/presentation/screens/home_screen.dart';
import 'package:hepatocheck_app/presentation/theme/app_theme.dart';
import 'package:hepatocheck_app/presentation/widgets/risk_card.dart';

import '../support/test_data.dart';

void main() {
  final now = DateTime(2026, 11, 11, 12);

  ProviderContainer newContainer() {
    final container = ProviderContainer(
      overrides: [
        clockProvider.overrideWithValue(() => now),
        report.clockProvider.overrideWithValue(() => now),
        examRepositoryProvider.overrideWithValue(MemoryExamRepository()),
        goalRepositoryProvider.overrideWithValue(InMemoryGoalRepository()),
        report.todayProvider.overrideWith(() => FixedTodayNotifier(now)),
        drinkRepositoryProvider.overrideWithValue(MemoryDrinkRepository()),
      ],
    );
    addTearDown(container.dispose);
    return container;
  }

  Future<void> show(
    WidgetTester tester,
    ProviderContainer container, {
    bool disableAnimations = false,
    Key? key,
  }) async {
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          theme: AppTheme.dark,
          home: MediaQuery(
            data: MediaQueryData(disableAnimations: disableAnimations),
            child: HomeScreen(key: key),
          ),
        ),
      ),
    );
    await tester.pump();
  }

  double cardOpacity(WidgetTester tester) => tester
      .widget<FadeTransition>(
        find
            .ancestor(
              of: find.byType(RiskCard),
              matching: find.byType(FadeTransition),
            )
            .first,
      )
      .opacity
      .value;

  testWidgets('na abertura, o scan roda antes de mostrar o cartão', (
    tester,
  ) async {
    await show(tester, newContainer());

    expect(cardOpacity(tester), 0);
    expect(find.byType(RiskCard), findsOneWidget);

    await tester.pump(const Duration(milliseconds: 1000));
    expect(cardOpacity(tester), 0);

    await tester.pumpAndSettle();
    expect(cardOpacity(tester), 1);
  });

  testWidgets('tocar na tela pula o scan', (tester) async {
    await show(tester, newContainer());
    await tester.pump(const Duration(milliseconds: 300));

    await tester.tapAt(const Offset(10, 300));
    await tester.pump();

    expect(cardOpacity(tester), 1);
  });

  testWidgets('ao voltar para o Início, o scan não roda de novo', (
    tester,
  ) async {
    final container = newContainer();
    await show(tester, container, key: const ValueKey(1));
    await tester.pumpAndSettle();

    await show(tester, container, key: const ValueKey(2));

    expect(cardOpacity(tester), 1);
  });

  testWidgets('com "remover animações", o resultado aparece direto', (
    tester,
  ) async {
    await show(tester, newContainer(), disableAnimations: true);

    expect(cardOpacity(tester), 1);
  });
}

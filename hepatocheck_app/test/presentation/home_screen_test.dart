import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hepatocheck_app/presentation/providers/liver_health_provider.dart';
import 'package:hepatocheck_app/presentation/providers/drink_providers.dart';
import 'package:hepatocheck_app/presentation/providers/exam_providers.dart';
import 'package:hepatocheck_app/presentation/screens/auth/login_screen.dart';
import 'package:hepatocheck_app/presentation/screens/home_screen.dart';
import 'package:hepatocheck_app/presentation/theme/app_theme.dart';

import '../support/test_data.dart';

void main() {
  final now = DateTime(2026, 11, 11, 12);

  Future<ProviderContainer> pump(WidgetTester tester) async {
    final container = ProviderContainer(
      overrides: [
        clockProvider.overrideWithValue(() => now),
        examRepositoryProvider.overrideWithValue(MemoryExamRepository()),
        drinkRepositoryProvider.overrideWithValue(MemoryDrinkRepository()),
      ],
    );
    addTearDown(container.dispose);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(theme: AppTheme.dark, home: const HomeScreen()),
      ),
    );
    await tester.pump();
    return container;
  }

  testWidgets('sem exame mostra o convite para registrar', (tester) async {
    await pump(tester);
    expect(find.textContaining('Registre um exame'), findsOneWidget);
    expect(find.text('0%'), findsOneWidget);
  });

  testWidgets('atualiza o medidor ao salvar exame e consumo', (tester) async {
    final container = await pump(tester);

    await container.read(examsProvider.notifier).save(testExam());
    await tester.pumpAndSettle();
    expect(find.text('72%'), findsOneWidget);
    expect(find.text('FIB-4: 0,90'), findsOneWidget);
    expect(find.text('Risco verde'), findsOneWidget);

    await container
        .read(drinksProvider.notifier)
        .save(testDrink(42, now.subtract(const Duration(days: 2))));
    await tester.pumpAndSettle();
    expect(find.text('65%'), findsOneWidget); // 72,3 - 7,5 = 64,8
    expect(find.textContaining('Acima do limite'), findsOneWidget);
  });

  testWidgets('login valida os campos e leva ao cadastro', (tester) async {
    await tester.pumpWidget(
      MaterialApp(theme: AppTheme.dark, home: const LoginScreen()),
    );

    await tester.tap(find.widgetWithText(FilledButton, 'Entrar'));
    await tester.pump();
    expect(find.text('Informe o e-mail.'), findsOneWidget);
    expect(find.text('Informe a senha.'), findsOneWidget);

    await tester.ensureVisible(find.text('Criar conta'));
    await tester.tap(find.text('Criar conta'));
    await tester.pumpAndSettle();
    expect(find.text('Confirmar senha'), findsOneWidget);
  });
}

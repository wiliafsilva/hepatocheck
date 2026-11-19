import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hepatocheck_app/domain/entities/lab_exam.dart';
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

  testWidgets('na mesma data usa o exame cadastrado por último', (
    tester,
  ) async {
    final container = await pump(tester);
    final date = DateTime(2026, 11, 1);
    await container.read(examsProvider.notifier).save(testExam(examDate: date));
    await container
        .read(examsProvider.notifier)
        .save(
          LabExam(
            id: 'e2',
            examDate: date,
            age: 45,
            ast: 60,
            alt: 36,
            platelets: 250,
            createdAt: date.add(const Duration(hours: 1)),
            updatedAt: date.add(const Duration(hours: 1)),
          ),
        );
    await tester.pumpAndSettle();

    expect(find.text('FIB-4: 1,80'), findsOneWidget);
    expect(find.text('Risco amarelo'), findsOneWidget);
  });

  testWidgets('selo de risco abre a orientação médica', (tester) async {
    final container = await pump(tester);
    await container.read(examsProvider.notifier).save(testExam());
    await tester.pumpAndSettle();

    await tester.tap(find.text('Risco verde'));
    await tester.pumpAndSettle();

    expect(find.text('Quando procurar o médico'), findsOneWidget);
    expect(find.text('Seu resultado'), findsOneWidget);
    expect(find.text('Risco amarelo'), findsOneWidget);
    expect(find.textContaining('não substitui uma avaliação'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('Risco vermelho'),
      200,
      scrollable: find.byType(Scrollable).last,
    );
    expect(find.text('Risco vermelho'), findsOneWidget);
  });

  testWidgets('risco alto mostra o filtro de icterícia e a explicação', (
    tester,
  ) async {
    final container = await pump(tester);
    expect(find.byType(JaundiceFilter), findsNothing);
    expect(find.byType(JaundiceNotice), findsNothing);

    await container
        .read(examsProvider.notifier)
        .save(testExam(age: 60, ast: 80, alt: 40, platelets: 120));
    await tester.pumpAndSettle();

    expect(find.byType(JaundiceFilter), findsOneWidget);
    expect(find.text('Por que a tela está amarelada?'), findsOneWidget);

    await tester.tap(find.text('Por que a tela está amarelada?'));
    await tester.pumpAndSettle();
    expect(find.text('Quando procurar o médico'), findsOneWidget);
  });

  testWidgets('risco verde ou amarelo não mostra o filtro', (tester) async {
    final container = await pump(tester);

    await container.read(examsProvider.notifier).save(testExam());
    await tester.pumpAndSettle();
    expect(find.byType(JaundiceFilter), findsNothing);

    await container
        .read(examsProvider.notifier)
        .save(testExam(id: 'e2', ast: 35, platelets: 181));
    await tester.pumpAndSettle();
    expect(find.byType(JaundiceFilter), findsNothing);
  });

  testWidgets('o filtro não bloqueia o toque nos botões', (tester) async {
    final container = await pump(tester);
    await container
        .read(examsProvider.notifier)
        .save(testExam(age: 60, ast: 80, alt: 40, platelets: 120));
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Registrar drinque'));
    await tester.pumpAndSettle();
    expect(find.byType(BottomSheet), findsOneWidget);
  });

  testWidgets('login valida os campos e leva ao cadastro', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(theme: AppTheme.dark, home: const LoginScreen()),
      ),
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

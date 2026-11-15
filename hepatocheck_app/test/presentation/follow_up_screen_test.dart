import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce/hive.dart';
import 'package:hepatocheck_app/data/notifications/local_follow_up_notifications.dart';
import 'package:hepatocheck_app/data/datasources/local/hive_database.dart';
import 'package:hepatocheck_app/presentation/providers/goal_providers.dart';
import 'package:hepatocheck_app/presentation/providers/drink_providers.dart';
import 'package:hepatocheck_app/presentation/providers/exam_providers.dart';
import 'package:hepatocheck_app/presentation/screens/follow_up_screen.dart';
import 'package:hepatocheck_app/presentation/screens/goals_screen.dart';
import 'package:hepatocheck_app/presentation/theme/app_theme.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import '../support/test_data.dart';
import 'goals_screen_test.dart' show MemoryGoalRepository;

class _BrowserNotifications extends LocalFollowUpNotifications {
  _BrowserNotifications() : super(HiveDatabase.followUp);
  @override
  bool get supported => false;
}

void main() {
  late Directory directory;
  late Box<String> box;
  setUpAll(() async {
    final loader = FontLoader('Inter');
    loader.addFont(
      Future.value(
        ByteData.sublistView(
          File('assets/fonts/Inter-Regular.ttf').readAsBytesSync(),
        ),
      ),
    );
    await loader.load();
  });
  setUp(() async {
    directory = await Directory.systemTemp.createTemp('follow-up-ui');
    Hive.init(directory.path);
    box = await Hive.openBox<String>(HiveDatabase.followUpBoxName);
  });
  tearDown(() async {
    await Hive.close();
    await directory.delete(recursive: true);
  });

  ProviderContainer container() => ProviderContainer(
    overrides: [
      localFollowUpProvider.overrideWithValue(_BrowserNotifications()),
      goalRepositoryProvider.overrideWithValue(MemoryGoalRepository()),
      drinkRepositoryProvider.overrideWithValue(MemoryDrinkRepository()),
      examRepositoryProvider.overrideWithValue(MemoryExamRepository()),
    ],
  );

  Widget app(ProviderContainer state, Widget screen, {double scale = 1}) =>
      UncontrolledProviderScope(
        container: state,
        child: MaterialApp(
          theme: AppTheme.dark,
          localizationsDelegates: GlobalMaterialLocalizations.delegates,
          supportedLocales: const [Locale('pt', 'BR')],
          locale: const Locale('pt', 'BR'),
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context)
                .copyWith(textScaler: TextScaler.linear(scale)),
            child: child!,
          ),
          home: screen,
        ),
      );

  testWidgets('salva preferências locais e intervalos por faixa', (
    tester,
  ) async {
    final state = container();
    addTearDown(state.dispose);
    await tester.pumpWidget(app(state, const FollowUpScreen()));
    await tester.scrollUntilVisible(
      find.text('Mensagens educativas e feedback de metas'),
      200,
    );
    await tester.tap(find.text('Mensagens educativas e feedback de metas'));
    await tester.pump();
    final input = find.widgetWithText(TextFormField, 'Risco baixo');
    await tester.scrollUntilVisible(
      input,
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.enterText(input, '12');
    await tester.scrollUntilVisible(
      find.text('Salvar preferências'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.runAsync(() async {
      await tester.tap(find.text('Salvar preferências'));
      await Future<void>.delayed(const Duration(milliseconds: 150));
    });
    await tester.pumpAndSettle();
    final saved = jsonDecode(box.get('settings')!) as Map;
    expect(saved['education'], isTrue);
    expect(saved['lowRiskMonths'], 12);
    expect(tester.takeException(), isNull);
  });

  for (final screen in [
    const FollowUpScreen(),
    const GoalsScreen(),
    const GoalFormScreen(),
  ]) {
    testWidgets(
      '${screen.runtimeType} em celular estreito com fonte ampliada',
      (tester) async {
        tester.view.physicalSize = const Size(320, 568);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.reset);
        final state = container();
        addTearDown(state.dispose);
        await tester.pumpWidget(app(state, screen, scale: 2));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
      },
    );
  }
}

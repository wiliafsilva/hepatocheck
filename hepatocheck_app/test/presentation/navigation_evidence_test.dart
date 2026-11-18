import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce/hive.dart';
import 'package:hepatocheck_app/app.dart';
import 'package:hepatocheck_app/data/datasources/local/hive_database.dart';
import 'package:hepatocheck_app/presentation/camouflage/camouflage_preferences_store.dart';
import 'package:hepatocheck_app/presentation/providers/auth_providers.dart';
import 'package:hepatocheck_app/presentation/providers/consent_providers.dart';
import 'package:hepatocheck_app/presentation/providers/drink_providers.dart';
import 'package:hepatocheck_app/presentation/providers/exam_providers.dart';
import 'package:hepatocheck_app/presentation/providers/goal_providers.dart';
import 'package:hepatocheck_app/presentation/providers/report_providers.dart';
import 'package:hepatocheck_app/presentation/providers/sync_providers.dart';
import 'package:hepatocheck_app/presentation/screens/camouflage_calculator_screen.dart';
import 'package:hepatocheck_app/presentation/screens/goals_screen.dart';
import 'package:hepatocheck_app/presentation/theme/app_theme.dart';

import '../support/fake_auth_repository.dart';
import '../support/test_data.dart';
import 'goals_screen_test.dart' show MemoryGoalRepository;

class _EmptySyncStatus extends SyncStatusNotifier {
  @override
  SyncStatusState build() => const SyncStatusState(pending: [], failed: []);
}

void main() {
  late Directory directory;
  late ProviderContainer state;
  final captureKey = GlobalKey();
  const capture = bool.fromEnvironment('CAPTURE_NAVIGATION');
  final now = DateTime(2026, 11, 18, 12);

  setUpAll(() async {
    final icons = FontLoader('MaterialIcons');
    icons.addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'));
    await icons.load();
    for (final family in ['Inter']) {
      final loader = FontLoader(family);
      for (final weight in ['Regular', 'Medium', 'SemiBold', 'Bold']) {
        loader.addFont(
          Future.value(
            ByteData.sublistView(
              File('assets/fonts/Inter-$weight.ttf').readAsBytesSync(),
            ),
          ),
        );
      }
      await loader.load();
    }
  });
  setUp(() async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          const MethodChannel('br.com.hepatocheck/app_privacy'),
          (_) async => null,
        );
    FlutterSecureStorage.setMockInitialValues({});
    directory = await Directory.systemTemp.createTemp('navigation-proof');
    Hive.init(directory.path);
    await Hive.openBox<String>(HiveDatabase.followUpBoxName);
    state = ProviderContainer(
      overrides: [
        authRepositoryProvider.overrideWithValue(FakeAuthRepository()),
        syncConsentRepositoryProvider.overrideWithValue(
          MemorySyncConsentRepository(),
        ),
        examRepositoryProvider.overrideWithValue(MemoryExamRepository()),
        drinkRepositoryProvider.overrideWithValue(MemoryDrinkRepository()),
        goalRepositoryProvider.overrideWithValue(MemoryGoalRepository()),
        syncStatusProvider.overrideWith(_EmptySyncStatus.new),
        clockProvider.overrideWithValue(() => now),
      ],
    );
    await state.read(examsProvider.notifier).save(testExam(examDate: now));
  });
  tearDown(() async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          const MethodChannel('br.com.hepatocheck/app_privacy'),
          null,
        );
    state.dispose();
    await Hive.close();
    await directory.delete(recursive: true);
  });

  Future<void> start(WidgetTester tester, {double scale = 1}) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: state,
        child: RepaintBoundary(
          key: captureKey,
          child: MaterialApp(
            debugShowCheckedModeBanner: false,
            theme: AppTheme.dark,
            locale: const Locale('pt', 'BR'),
            supportedLocales: const [Locale('pt', 'BR')],
            localizationsDelegates: GlobalMaterialLocalizations.delegates,
            builder: (context, child) => MediaQuery(
              data: MediaQuery.of(context)
                  .copyWith(textScaler: TextScaler.linear(scale)),
              child: child!,
            ),
            home: const AppNavigationShell(),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<void> shot(WidgetTester tester, String name) async {
    expect(tester.takeException(), isNull);
    if (!capture) return;
    final boundary =
        captureKey.currentContext!.findRenderObject()! as RenderRepaintBoundary;
    await tester.runAsync(() async {
      final image = await boundary.toImage(pixelRatio: 2);
      final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
      final folder = Directory('../docs/imagens/navegacao');
      await folder.create(recursive: true);
      await File('${folder.path}/$name.png')
          .writeAsBytes(bytes!.buffer.asUint8List());
      image.dispose();
    });
  }

  Future<void> tap(WidgetTester tester, Finder target) async {
    await tester.ensureVisible(target);
    await tester.tap(target);
    await tester.pumpAndSettle();
  }

  Future<void> tab(WidgetTester tester, String name) => tap(
    tester,
    find.descendant(of: find.byType(NavigationBar), matching: find.text(name)),
  );

  testWidgets('A9: navega pelas abas e rotas reais com dados fictícios', (
    tester,
  ) async {
    await start(tester);
    await shot(tester, '01-inicio');
    await tap(tester, find.byTooltip('Registrar drinque'));
    await shot(tester, '02-registro-rapido');
    tester.state<NavigatorState>(find.byType(Navigator).first).pop();
    await tester.pumpAndSettle();
    await tab(tester, 'Relatório');
    await shot(tester, '03-relatorio');
    await tab(tester, 'Drinks');
    await shot(tester, '04-drinks');
    await tap(tester, find.byTooltip('Metas de redução'));
    expect(find.byType(GoalsScreen), findsOneWidget);
    await shot(tester, '05-metas');
    await tap(tester, find.text('Criar meta'));
    await shot(tester, '06-criar-meta');
    tester.state<NavigatorState>(find.byType(Navigator).first).pop();
    await tester.pumpAndSettle();
    tester.state<NavigatorState>(find.byType(Navigator).first).pop();
    await tester.pumpAndSettle();
    await tab(tester, 'Exames');
    await shot(tester, '07-exames');
    await tab(tester, 'Perfil');
    await shot(tester, '08-perfil');
    await tap(tester, find.text('Notificações e lembretes'));
    await shot(tester, '09-notificacoes');
    tester.state<NavigatorState>(find.byType(Navigator).first).pop();
    await tester.pumpAndSettle();
    await tap(tester, find.text('Entrar ou criar conta'));
    await shot(tester, '10-login');
    await tap(tester, find.text('Criar conta'));
    await shot(tester, '11-cadastro');
    tester.state<NavigatorState>(find.byType(Navigator).first).pop();
    await tester.pumpAndSettle();
    await tap(tester, find.text('Esqueci minha senha'));
    await shot(tester, '12-recuperacao');
    tester.state<NavigatorState>(find.byType(Navigator).first).pop();
    await tester.pumpAndSettle();
    tester.state<NavigatorState>(find.byType(Navigator).first).pop();
    await tester.pumpAndSettle();
    await tap(tester, find.text('Sincronização'));
    await shot(tester, '13-sincronizacao');
    tester.state<NavigatorState>(find.byType(Navigator).first).pop();
    await tester.pumpAndSettle();
    await state
        .read(examsProvider.notifier)
        .save(
          testExam(
            id: 'alto',
            examDate: now.add(const Duration(days: 1)),
            ast: 150,
            platelets: 100,
          ),
        );
    await tab(tester, 'Início');
    expect(
      find.byKey(const ValueKey('high-risk-yellow-filter')),
      findsOneWidget,
    );
    await shot(tester, '14-risco-alto');
  });

  testWidgets('camuflagem fecha rotas sensíveis e desbloqueia em Drinks', (
    tester,
  ) async {
    await CamouflagePreferencesStore().enable('2580');
    await start(tester);
    expect(find.byType(CamouflageCalculatorScreen), findsOneWidget);
    await shot(tester, '15-camuflagem');
    Future<void> unlock() async {
      for (final digit in ['2', '5', '8', '0']) {
        await tap(tester, find.bySemanticsLabel('Tecla $digit'));
      }
      expect(find.byType(CamouflageCalculatorScreen), findsNothing);
    }

    await unlock();
    final bar = tester.widget<NavigationBar>(find.byType(NavigationBar));
    expect(bar.selectedIndex, 2);
    await tap(tester, find.byTooltip('Metas de redução'));
    expect(find.byType(GoalsScreen), findsOneWidget);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    await tester.pumpAndSettle();
    expect(find.byType(GoalsScreen), findsNothing);
    expect(find.byType(CamouflageCalculatorScreen), findsOneWidget);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pumpAndSettle();
    await unlock();
    expect(find.byType(GoalsScreen), findsNothing);
  });
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hepatocheck_app/domain/repositories/local_data_eraser.dart';
import 'package:hepatocheck_app/presentation/providers/account_session.dart';
import 'package:hepatocheck_app/presentation/providers/auth_providers.dart';
import 'package:hepatocheck_app/presentation/providers/consent_providers.dart';
import 'package:hepatocheck_app/presentation/providers/local_data_providers.dart';
import 'package:hepatocheck_app/presentation/providers/sync_providers.dart';
import 'package:hepatocheck_app/presentation/screens/auth/change_password_screen.dart';
import 'package:hepatocheck_app/presentation/screens/profile_screen.dart';
import 'package:hepatocheck_app/presentation/theme/app_theme.dart';

import '../support/fake_auth_repository.dart';
import '../support/sync_fakes.dart';

class _CountingEraser implements LocalDataEraser {
  int calls = 0;

  @override
  Future<void> eraseAll() async => calls++;
}

void main() {
  late FakeAuthRepository auth;
  late FakeCloudRestore cloud;
  late _CountingEraser eraser;
  late MemorySyncConsentRepository consent;
  late FakeCloudVault vault;

  Future<void> pump(WidgetTester tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.6;
    addTearDown(tester.view.reset);
    auth = FakeAuthRepository();
    consent = MemorySyncConsentRepository();
    vault = FakeCloudVault(unlocked: true);
    cloud = FakeCloudRestore();
    eraser = _CountingEraser();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authRepositoryProvider.overrideWithValue(auth),
          syncConsentRepositoryProvider.overrideWithValue(consent),
          cloudVaultProvider.overrideWithValue(vault),
          syncQueueRepositoryProvider.overrideWithValue(MemorySyncQueue()),
          cloudRestoreProvider.overrideWithValue(cloud),
          localDataEraserProvider.overrideWithValue(eraser),
        ],
        child: MaterialApp(
          theme: AppTheme.dark,
          home: Scaffold(
            body: ProfileScreen(
              camouflageEnabled: false,
              onEnableCamouflage: (_) async {},
              onDisableCamouflage: () async {},
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<void> reveal(WidgetTester tester, Finder finder) async {
    await tester.scrollUntilVisible(
      finder,
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
  }

  testWidgets('convidado vê os grupos e não vê a parte da conta', (
    tester,
  ) async {
    await pump(tester);

    expect(find.text('Modo convidado'), findsOneWidget);
    await tester.tap(find.text('Modo convidado'));
    await tester.pumpAndSettle();
    expect(find.text('Seu fígado, sob controle.'), findsOneWidget);
    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(find.text('PRIVACIDADE E SINCRONIZAÇÃO'), findsOneWidget);
    expect(find.text('Sincronização na nuvem'), findsNothing);
    await reveal(tester, find.text('Apagar todos os dados'));
    expect(find.text('ACOMPANHAMENTO'), findsOneWidget);
    expect(find.text('Exportar resumo em PDF'), findsOneWidget);
    expect(find.text('CONTA'), findsNothing);
    expect(find.text('Sair da conta'), findsNothing);
  });

  testWidgets('conectada, a conta aparece com Alterar senha e Sair', (
    tester,
  ) async {
    await pump(tester);
    await auth.signIn(email: 'a@b.com', password: '123456');
    await tester.pumpAndSettle();

    expect(find.text('a@b.com'), findsOneWidget);
    final userTile = tester.widget<ListTile>(
      find.ancestor(of: find.text('a@b.com'), matching: find.byType(ListTile)),
    );
    expect(userTile.onTap, isNull);
    expect(find.text('Sincronização na nuvem'), findsOneWidget);
    await reveal(tester, find.text('Sair da conta'));
    await tester.tap(find.text('Alterar senha'));
    await tester.pumpAndSettle();
    expect(find.byType(ChangePasswordScreen), findsOneWidget);

    await tester.pageBack();
    await tester.pumpAndSettle();
    await tester.tap(find.text('Sair da conta'));
    await tester.pumpAndSettle();
    expect(find.text('Sair da conta?'), findsOneWidget);
    expect(find.textContaining('Seus registros continuam'), findsOneWidget);
    await tester.tap(find.text('Cancelar'));
    await tester.pumpAndSettle();
    expect(auth.currentUser, isNotNull);

    await tester.tap(find.text('Sair da conta'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(TextButton, 'Sair'));
    await tester.pumpAndSettle();

    expect(auth.currentUser, isNull);
    expect(consent.isGranted, isFalse);
    expect(vault.isUnlocked, isFalse);
    await tester.drag(find.byType(Scrollable).first, const Offset(0, 3000));
    await tester.pumpAndSettle();
    expect(find.text('Modo convidado'), findsOneWidget);
  });

  testWidgets('o atalho do PDF abre o resumo com os dois botões', (
    tester,
  ) async {
    await pump(tester);
    await reveal(tester, find.text('Exportar resumo em PDF'));

    await tester.tap(find.text('Exportar resumo em PDF'));
    await tester.pumpAndSettle();

    expect(find.byType(ExportSummaryScreen), findsOneWidget);
    expect(find.text('Visualizar / salvar'), findsOneWidget);
    expect(find.text('Compartilhar'), findsOneWidget);
  });

  Future<void> deleteAccountWith(WidgetTester tester, String password) async {
    await reveal(tester, find.text('Apagar a conta'));
    await tester.tap(find.text('Apagar a conta'));
    await tester.pumpAndSettle();
    expect(find.text('Apagar a conta?'), findsOneWidget);
    await tester.enterText(find.byType(TextField), password);
    await tester.tap(find.widgetWithText(TextButton, 'Apagar conta'));
    await tester.pumpAndSettle();
  }

  testWidgets('apagar a conta apaga nuvem, chave, aparelho e a conta', (
    tester,
  ) async {
    await pump(tester);
    await auth.signIn(email: 'a@b.com', password: '123456');
    await tester.pumpAndSettle();

    await deleteAccountWith(tester, '123456');

    expect(cloud.deletedUids, ['uid-1']);
    expect(cloud.deletedKeys, ['uid-1']);
    expect(eraser.calls, 1);
    expect(vault.isUnlocked, isFalse);
    expect(auth.deleted, isTrue);
    expect(
      find.text('Sua conta e todos os seus dados foram apagados.'),
      findsOneWidget,
    );
  });

  testWidgets('senha errada ou sem internet, nada é apagado', (tester) async {
    await pump(tester);
    await auth.signIn(email: 'a@b.com', password: '123456');
    await tester.pumpAndSettle();

    await deleteAccountWith(tester, 'errada-1');
    expect(
      find.text('A senha está incorreta. Nada foi apagado.'),
      findsOneWidget,
    );

    cloud.offline = true;
    await tester.pump(const Duration(seconds: 5));
    await deleteAccountWith(tester, '123456');
    expect(
      find.text('Conecte-se à internet para apagar a conta. Nada foi apagado.'),
      findsOneWidget,
    );

    expect(cloud.deletedUids, isEmpty);
    expect(eraser.calls, 0);
    expect(auth.deleted, isFalse);
    expect(auth.currentUser, isNotNull);
  });
}

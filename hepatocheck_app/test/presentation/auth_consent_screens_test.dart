import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hepatocheck_app/domain/repositories/auth_repository.dart';
import 'package:hepatocheck_app/domain/repositories/cloud_restore.dart';
import 'package:hepatocheck_app/presentation/providers/account_session.dart';
import 'package:hepatocheck_app/presentation/providers/auth_providers.dart';
import 'package:hepatocheck_app/presentation/providers/consent_providers.dart';
import 'package:hepatocheck_app/presentation/providers/sync_providers.dart';
import 'package:hepatocheck_app/presentation/screens/auth/account_screen.dart';
import 'package:hepatocheck_app/presentation/screens/auth/auth_widgets.dart';
import 'package:hepatocheck_app/presentation/screens/auth/change_password_screen.dart';
import 'package:hepatocheck_app/presentation/screens/auth/forgot_password_screen.dart';
import 'package:hepatocheck_app/presentation/screens/auth/login_screen.dart';
import 'package:hepatocheck_app/presentation/screens/auth/register_screen.dart';
import 'package:hepatocheck_app/presentation/screens/sync_consent_screen.dart';
import 'package:hepatocheck_app/presentation/theme/app_theme.dart';

import '../support/fake_auth_repository.dart';
import '../support/sync_fakes.dart';

Future<void> reveal(WidgetTester tester, Finder finder) => tester
    .scrollUntilVisible(finder, 200, scrollable: find.byType(Scrollable).first);

void main() {
  late FakeAuthRepository auth;
  late MemorySyncConsentRepository consent;
  late ProviderContainer container;
  late FakeCloudVault vault;
  late FakeCloudRestore restore;

  Future<void> pump(WidgetTester tester, Widget home) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.6;
    addTearDown(tester.view.reset);
    auth = FakeAuthRepository();
    consent = MemorySyncConsentRepository();
    vault = FakeCloudVault(unlocked: false);
    restore = FakeCloudRestore(
      report: const RestoreReport(drinks: 8, exams: 2, goals: 1),
    );
    container = ProviderContainer(
      overrides: [
        authRepositoryProvider.overrideWithValue(auth),
        cloudVaultProvider.overrideWithValue(vault),
        cloudRestoreProvider.overrideWithValue(restore),
        syncConsentRepositoryProvider.overrideWithValue(consent),
        syncQueueRepositoryProvider.overrideWithValue(MemorySyncQueue()),
      ],
    );
    addTearDown(container.dispose);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          theme: AppTheme.dark,
          home: Builder(
            builder: (context) => Scaffold(
              body: Center(
                child: TextButton(
                  onPressed: () =>
                      Navigator.of(context)
                          .push(MaterialPageRoute<void>(builder: (_) => home)),
                  child: const Text('abrir'),
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('abrir'));
    await tester.pumpAndSettle();
  }

  testWidgets('login com sucesso abre o consentimento quando ainda não há', (
    tester,
  ) async {
    await pump(tester, const LoginScreen());

    await tester.enterText(
      find.widgetWithText(AuthTextField, 'E-mail'),
      'a@b.com',
    );
    await tester.enterText(
      find.widgetWithText(AuthTextField, 'Senha'),
      '123456',
    );
    await tester.tap(find.widgetWithText(FilledButton, 'Entrar'));
    await tester.pumpAndSettle();

    expect(auth.currentUser?.email, 'a@b.com');
    expect(find.byType(SyncConsentScreen), findsOneWidget);
    expect(container.read(syncConsentProvider), isFalse);
  });

  testWidgets('login com senha errada mostra a mensagem e continua na tela', (
    tester,
  ) async {
    await pump(tester, const LoginScreen());
    auth.failure = AuthFailureCode.wrongCredentials;

    await tester.enterText(
      find.widgetWithText(AuthTextField, 'E-mail'),
      'a@b.com',
    );
    await tester.enterText(
      find.widgetWithText(AuthTextField, 'Senha'),
      '123456',
    );
    await tester.tap(find.widgetWithText(FilledButton, 'Entrar'));
    await tester.pumpAndSettle();

    expect(find.text('E-mail ou senha incorretos.'), findsOneWidget);
    expect(find.byType(LoginScreen), findsOneWidget);
    expect(auth.currentUser, isNull);
  });

  testWidgets('login ignora uma segunda submissão enquanto está entrando', (
    tester,
  ) async {
    final gate = Completer<void>();
    var calls = 0;
    await pump(
      tester,
      LoginScreen(
        onSubmit: (_, _) {
          calls++;
          return gate.future;
        },
      ),
    );

    await tester.enterText(
      find.widgetWithText(AuthTextField, 'E-mail'),
      'a@b.com',
    );
    await tester.enterText(
      find.widgetWithText(AuthTextField, 'Senha'),
      '123456',
    );
    final submit = find.widgetWithText(FilledButton, 'Entrar');
    await tester.tap(submit);
    await tester.tap(submit);
    await tester.pump();

    expect(calls, 1);
    gate.complete();
    await tester.pumpAndSettle();
  });

  testWidgets('modo convidado: sair do login não exige conta', (tester) async {
    await pump(tester, const LoginScreen());

    await reveal(tester, find.text('Continuar como convidado'));
    await tester.tap(find.text('Continuar como convidado'));
    await tester.pumpAndSettle();

    expect(find.byType(LoginScreen), findsNothing);
    expect(auth.currentUser, isNull);
  });

  testWidgets('recuperação de senha envia o e-mail e não revela a conta', (
    tester,
  ) async {
    await pump(tester, const ForgotPasswordScreen());

    await tester.tap(
      find.widgetWithText(FilledButton, 'Enviar link de recuperação'),
    );
    await tester.pump();
    expect(find.text('Informe o e-mail.'), findsOneWidget);

    await tester.enterText(find.byType(TextFormField), 'a@b.com');
    await tester.tap(
      find.widgetWithText(FilledButton, 'Enviar link de recuperação'),
    );
    await tester.pumpAndSettle();
    expect(
      find.text('Seus dados ficam trancados com a sua senha'),
      findsOneWidget,
    );
    final proceed = find.widgetWithText(FilledButton, 'Continuar');
    expect(tester.widget<FilledButton>(proceed).onPressed, isNull);
    await tester.ensureVisible(find.text('Entendi'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Entendi'));
    await tester.pump();
    await tester.tap(proceed);
    await tester.pumpAndSettle();

    expect(auth.resetEmails, ['a@b.com']);
    expect(find.textContaining('Se houver uma conta'), findsOneWidget);
  });

  testWidgets('consentimento: autorizar liga o envio e revogar desliga', (
    tester,
  ) async {
    await pump(tester, const SyncConsentScreen());
    expect(container.read(syncConsentProvider), isFalse);
    expect(
      find.textContaining('criptografada com a sua senha'),
      findsOneWidget,
    );
    await tester.scrollUntilVisible(
      find.textContaining('nunca é enviado'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.textContaining('nunca é enviado'), findsOneWidget);

    await tester.scrollUntilVisible(
      find.text('Autorizar sincronização'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.text('Autorizar sincronização'));
    await tester.pumpAndSettle();
    expect(consent.isGranted, isTrue);
    expect(container.read(syncConsentProvider), isTrue);
  });

  testWidgets('consentimento: revogar desliga e apaga a autorização', (
    tester,
  ) async {
    await pump(tester, const SyncConsentScreen());
    await container.read(syncConsentControllerProvider.notifier).grant();
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(
      find.text('Revogar autorização'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.text('Revogar autorização'));
    await tester.pumpAndSettle();

    expect(consent.isGranted, isFalse);
    expect(container.read(syncConsentProvider), isFalse);
  });

  testWidgets('sair da conta encerra a sessão e revoga o consentimento', (
    tester,
  ) async {
    await pump(tester, const AccountScreen());
    await auth.signIn(email: 'a@b.com', password: '123456');
    await container.read(syncConsentControllerProvider.notifier).grant();
    await tester.pumpAndSettle();
    expect(find.text('a@b.com'), findsOneWidget);

    await tester.tap(find.text('Sair da conta'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(TextButton, 'Sair'));
    await tester.pumpAndSettle();

    expect(auth.currentUser, isNull);
    expect(consent.isGranted, isFalse);
    expect(container.read(syncConsentProvider), isFalse);
    expect(vault.isUnlocked, isFalse);
  });

  Future<void> signInThroughScreen(WidgetTester tester) async {
    await tester.enterText(
      find.widgetWithText(AuthTextField, 'E-mail'),
      'a@b.com',
    );
    await tester.enterText(
      find.widgetWithText(AuthTextField, 'Senha'),
      '123456',
    );
    await tester.tap(find.widgetWithText(FilledButton, 'Entrar'));
    await tester.pumpAndSettle();
  }

  testWidgets('login abre o cofre, restaura os dados e avisa', (tester) async {
    await pump(tester, const LoginScreen());

    await signInThroughScreen(tester);

    expect(vault.isUnlocked, isTrue);
    expect(restore.restoredUids, ['uid-1']);
    expect(
      find.text('Seus dados foram restaurados: 8 drinques, 2 exames e 1 meta.'),
      findsOneWidget,
    );
  });

  testWidgets(
    'senha recuperada gera chave nova, apaga a cópia antiga e avisa',
    (tester) async {
      await pump(tester, const LoginScreen());
      vault.keyMismatch = true;

      await signInThroughScreen(tester);

      expect(vault.resets, 1);
      expect(restore.deletedUids, ['uid-1']);
      expect(restore.restoredUids, ['uid-1']);
      expect(find.textContaining('a cópia antiga da nuvem'), findsOneWidget);
    },
  );

  testWidgets('cadastro só cria a conta depois de aceitar o aviso', (
    tester,
  ) async {
    await pump(tester, const RegisterScreen());
    await tester.enterText(
      find.widgetWithText(AuthTextField, 'E-mail'),
      'a@b.com',
    );
    await tester.enterText(
      find.widgetWithText(AuthTextField, 'Senha'),
      'senha-forte-1',
    );
    await tester.enterText(
      find.widgetWithText(AuthTextField, 'Confirmar senha'),
      'senha-forte-1',
    );
    final create = find.widgetWithText(FilledButton, 'Criar conta');

    await reveal(
      tester,
      find.text('Aceite a política de privacidade para continuar'),
    );
    expect(tester.widget<FilledButton>(create).onPressed, isNull);
    await tester.tap(find.byType(Checkbox));
    await tester.pump();
    expect(tester.widget<FilledButton>(create).onPressed, isNotNull);

    await tester.tap(create);
    await tester.pumpAndSettle();
    expect(
      find.text('Seus dados ficam trancados com a sua senha'),
      findsOneWidget,
    );
    await tester.tap(find.text('Cancelar'));
    await tester.pumpAndSettle();
    expect(auth.currentUser, isNull);

    await tester.tap(create);
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Entendi'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Entendi'));
    await tester.pump();
    await tester.tap(find.widgetWithText(FilledButton, 'Continuar'));
    await tester.pumpAndSettle();

    expect(auth.currentUser?.email, 'a@b.com');
    expect(vault.isUnlocked, isTrue);
  });

  Future<void> openChangePassword(WidgetTester tester) async {
    await pump(tester, const ChangePasswordScreen());
    await auth.signIn(email: 'a@b.com', password: '123456');
    vault.unlocked = true;
    await tester.pumpAndSettle();
  }

  Future<void> fillChangePassword(
    WidgetTester tester, {
    String current = '123456',
  }) async {
    await tester.enterText(
      find.widgetWithText(AuthTextField, 'Senha atual'),
      current,
    );
    await tester.enterText(
      find.widgetWithText(AuthTextField, 'Nova senha'),
      'senha-nova-1',
    );
    await tester.enterText(
      find.widgetWithText(AuthTextField, 'Confirmar senha'),
      'senha-nova-1',
    );
    final save = find.widgetWithText(FilledButton, 'Salvar nova senha');
    await reveal(tester, save);
    await tester.tap(save);
    await tester.pumpAndSettle();
  }

  testWidgets('alterar senha troca a senha e retranca a chave da nuvem', (
    tester,
  ) async {
    await openChangePassword(tester);

    await fillChangePassword(tester);

    expect(auth.passwordChanges, ['senha-nova-1']);
    expect(vault.rewraps, ['senha-nova-1']);
    expect(find.text('Senha alterada.'), findsOneWidget);
    expect(find.byType(ChangePasswordScreen), findsNothing);
  });

  testWidgets('alterar senha com a senha atual errada não muda nada', (
    tester,
  ) async {
    await openChangePassword(tester);

    await fillChangePassword(tester, current: 'errada-1');

    expect(find.text('A senha atual está incorreta.'), findsOneWidget);
    expect(auth.passwordChanges, isEmpty);
    expect(vault.rewraps, isEmpty);
  });

  testWidgets(
    'se o Firebase recusar a senha nova, a chave volta para a atual',
    (tester) async {
      await openChangePassword(tester);
      auth.failUpdate = true;

      await fillChangePassword(tester);

      expect(auth.passwordChanges, isEmpty);
      expect(vault.rewraps, ['senha-nova-1', '123456']);
      expect(find.byType(ChangePasswordScreen), findsOneWidget);
      expect(find.textContaining('Sem conexão'), findsOneWidget);
    },
  );

  testWidgets('a conta leva para Alterar senha', (tester) async {
    await pump(tester, const AccountScreen());
    await auth.signIn(email: 'a@b.com', password: '123456');
    await tester.pumpAndSettle();

    await tester.tap(find.text('Alterar senha'));
    await tester.pumpAndSettle();

    expect(find.byType(ChangePasswordScreen), findsOneWidget);
    expect(find.text('A NOVA SENHA PRECISA TER'), findsOneWidget);
  });

  for (final (name, screen) in [
    ('login', const LoginScreen()),
    ('criar conta', const RegisterScreen()),
    ('esqueceu a senha', const ForgotPasswordScreen()),
    ('alterar senha', const ChangePasswordScreen()),
  ]) {
    testWidgets('$name cabe em celular pequeno com fonte em dobro', (
      tester,
    ) async {
      await pump(tester, screen);
      tester.view.physicalSize = const Size(320, 568);
      tester.view.devicePixelRatio = 1;
      tester.platformDispatcher.textScaleFactorTestValue = 2;
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      await tester.pumpAndSettle();
      await tester.drag(find.byType(Scrollable).first, const Offset(0, -3000));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
    });
  }
}

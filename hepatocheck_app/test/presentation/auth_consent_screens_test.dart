import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hepatocheck_app/domain/repositories/auth_repository.dart';
import 'package:hepatocheck_app/presentation/providers/auth_providers.dart';
import 'package:hepatocheck_app/presentation/providers/consent_providers.dart';
import 'package:hepatocheck_app/presentation/providers/sync_providers.dart';
import 'package:hepatocheck_app/presentation/screens/auth/account_screen.dart';
import 'package:hepatocheck_app/presentation/screens/auth/forgot_password_screen.dart';
import 'package:hepatocheck_app/presentation/screens/auth/login_screen.dart';
import 'package:hepatocheck_app/presentation/screens/sync_consent_screen.dart';
import 'package:hepatocheck_app/presentation/theme/app_theme.dart';

import '../support/fake_auth_repository.dart';
import '../support/sync_fakes.dart';

void main() {
  late FakeAuthRepository auth;
  late MemorySyncConsentRepository consent;
  late ProviderContainer container;

  Future<void> pump(WidgetTester tester, Widget home) async {
    auth = FakeAuthRepository();
    consent = MemorySyncConsentRepository();
    container = ProviderContainer(
      overrides: [
        authRepositoryProvider.overrideWithValue(auth),
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
      find.widgetWithText(TextFormField, 'E-mail'),
      'a@b.com',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Senha'),
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
      find.widgetWithText(TextFormField, 'E-mail'),
      'a@b.com',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Senha'),
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
      find.widgetWithText(TextFormField, 'E-mail'),
      'a@b.com',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Senha'),
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

    await tester.ensureVisible(find.text('Continuar como convidado'));
    await tester.tap(find.text('Continuar como convidado'));
    await tester.pumpAndSettle();

    expect(find.byType(LoginScreen), findsNothing);
    expect(auth.currentUser, isNull);
  });

  testWidgets('recuperação de senha envia o e-mail e não revela a conta', (
    tester,
  ) async {
    await pump(tester, const ForgotPasswordScreen());

    await tester.tap(find.widgetWithText(FilledButton, 'Enviar link'));
    await tester.pump();
    expect(find.text('Informe o e-mail.'), findsOneWidget);

    await tester.enterText(find.byType(TextFormField), 'a@b.com');
    await tester.tap(find.widgetWithText(FilledButton, 'Enviar link'));
    await tester.pumpAndSettle();

    expect(auth.resetEmails, ['a@b.com']);
    expect(find.textContaining('Se houver uma conta'), findsOneWidget);
  });

  testWidgets('consentimento: autorizar liga o envio e revogar desliga', (
    tester,
  ) async {
    await pump(tester, const SyncConsentScreen());
    expect(container.read(syncConsentProvider), isFalse);
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

    expect(auth.currentUser, isNull);
    expect(consent.isGranted, isFalse);
    expect(container.read(syncConsentProvider), isFalse);
  });
}

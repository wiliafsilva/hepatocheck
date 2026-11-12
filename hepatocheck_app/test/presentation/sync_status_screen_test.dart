import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hepatocheck_app/core/network/wifi_monitor.dart';
import 'package:hepatocheck_app/domain/entities/sync_item.dart';
import 'package:hepatocheck_app/presentation/providers/sync_providers.dart';
import 'package:hepatocheck_app/presentation/screens/sync_status_screen.dart';
import 'package:hepatocheck_app/presentation/theme/app_theme.dart';

import '../support/sync_fakes.dart';

void main() {
  late MemorySyncQueue queue;
  late FakeSyncRemote remote;

  setUp(() {
    queue = MemorySyncQueue();
    remote = FakeSyncRemote();
  });

  Future<void> pump(
    WidgetTester tester, {
    bool consent = true,
    bool onWifi = true,
    String? userId = 'usuario-1',
  }) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.6;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          syncQueueRepositoryProvider.overrideWithValue(queue),
          syncRemoteProvider.overrideWithValue(remote),
          currentUserIdProvider.overrideWithValue(() => userId),
          syncConsentProvider.overrideWithValue(consent),
          wifiMonitorProvider.overrideWithValue(
            WifiMonitor(
              checkConnectivity: () async => [
                onWifi ? ConnectivityResult.wifi : ConnectivityResult.mobile,
              ],
              connectivityChanges: const Stream.empty(),
            ),
          ),
        ],
        child: MaterialApp(
          theme: AppTheme.dark,
          home: const SyncStatusScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<void> enqueue(String entityId) => queue.enqueue(
    entityType: SyncEntityType.exam,
    entityId: entityId,
    operation: SyncOperation.create,
    payload: const {'ast': 38},
  );

  Finder counter(String label) =>
      find.ancestor(of: find.text(label), matching: find.byType(Card));

  testWidgets('mostra os pendentes e envia ao tocar em Sincronizar agora', (
    tester,
  ) async {
    await enqueue('exame-1');
    await enqueue('exame-2');
    await pump(tester);

    expect(
      find.descendant(
        of: counter('Aguardando envio'),
        matching: find.text('2'),
      ),
      findsOneWidget,
    );

    await tester.tap(find.text('Sincronizar agora'));
    await tester.pumpAndSettle();

    expect(queue.items, isEmpty);
    expect(find.text('2 registros enviados.'), findsOneWidget);
  });

  testWidgets('mostra os que falharam e permite tentar de novo', (
    tester,
  ) async {
    await enqueue('exame-1');
    await enqueue('exame-2');
    remote.rejected.add('exame-2');
    await pump(tester);

    await tester.tap(find.text('Sincronizar agora'));
    await tester.pumpAndSettle();

    expect(find.textContaining('2 registros com falha'), findsOneWidget);
    expect(find.text('NÃO ENVIADOS (2)'), findsOneWidget);
    expect(
      find.text('Sem permissão no servidor · 1 tentativa'),
      findsNWidgets(2),
    );

    remote.rejected.clear();
    await tester.ensureVisible(find.text('Tentar de novo'));
    await tester.tap(find.text('Tentar de novo'));
    await tester.pumpAndSettle();

    expect(queue.items, isEmpty);
    expect(find.text('Tentar de novo'), findsNothing);
    expect(find.text('2 registros enviados.'), findsOneWidget);
  });

  testWidgets('explica por que não enviou sem consentimento', (tester) async {
    await enqueue('exame-1');
    await pump(tester, consent: false);

    await tester.tap(find.text('Sincronizar agora'));
    await tester.pumpAndSettle();

    expect(
      find.textContaining('A sincronização está desligada'),
      findsOneWidget,
    );
    expect(queue.pending(), hasLength(1));
  });

  testWidgets('explica por que não enviou fora do Wi-Fi e sem conta', (
    tester,
  ) async {
    await enqueue('exame-1');
    await pump(tester, onWifi: false);
    await tester.tap(find.text('Sincronizar agora'));
    await tester.pumpAndSettle();
    expect(
      find.text('Conecte-se a uma rede Wi-Fi para sincronizar.'),
      findsOneWidget,
    );

    await pump(tester, userId: null);
    await tester.tap(find.text('Sincronizar agora'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Entre na sua conta'), findsOneWidget);
  });

  testWidgets('cabe em celular pequeno com fonte em dobro', (tester) async {
    await enqueue('exame-1');
    await enqueue('exame-2');
    remote.rejected.add('exame-2');
    await pump(tester);
    tester.view.physicalSize = const Size(320, 568);
    tester.view.devicePixelRatio = 1;
    tester.platformDispatcher.textScaleFactorTestValue = 2;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(
      find.text('Sincronizar agora'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.text('Sincronizar agora'));
    await tester.pumpAndSettle();
    expect(find.textContaining('com falha.'), findsOneWidget);
    await tester.drag(find.byType(Scrollable).first, const Offset(0, -2000));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
  });

  testWidgets('sem pendentes, o botão de sincronizar fica desativado', (
    tester,
  ) async {
    await pump(tester);

    final button = tester.widget<ButtonStyleButton>(
      find.ancestor(
        of: find.text('Sincronizar agora'),
        matching: find.bySubtype<ButtonStyleButton>(),
      ),
    );
    expect(button.onPressed, isNull);
  });
}

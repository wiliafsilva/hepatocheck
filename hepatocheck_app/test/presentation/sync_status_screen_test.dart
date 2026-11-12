import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hepatocheck_app/core/network/wifi_monitor.dart';
import 'package:hepatocheck_app/domain/entities/sync_item.dart';
import 'package:hepatocheck_app/domain/repositories/sync_queue_repository.dart';
import 'package:hepatocheck_app/domain/repositories/sync_remote.dart';
import 'package:hepatocheck_app/presentation/providers/sync_providers.dart';
import 'package:hepatocheck_app/presentation/screens/sync_status_screen.dart';
import 'package:hepatocheck_app/presentation/theme/app_theme.dart';

class _MemoryQueue implements SyncQueueRepository {
  final items = <String, SyncItem>{};
  var _counter = 0;

  @override
  Future<void> enqueue({
    required SyncEntityType entityType,
    required String entityId,
    required SyncOperation operation,
    required Map<String, dynamic> payload,
  }) async {
    final id = 'item-${++_counter}';
    items[id] = SyncItem(
      id: id,
      entityType: entityType,
      entityId: entityId,
      operation: operation,
      payload: payload,
      createdAt: DateTime(2026, 11, 16, 8, 0, _counter),
    );
  }

  List<SyncItem> _byStatus(SyncStatus status) =>
      items.values.where((item) => item.status == status).toList();

  @override
  List<SyncItem> pending() => _byStatus(SyncStatus.pending);

  @override
  List<SyncItem> failed() => _byStatus(SyncStatus.failed);

  @override
  Future<void> markSending(Iterable<String> ids) async {
    for (final id in ids) {
      items[id] = items[id]!.copyWith(status: SyncStatus.sending);
    }
  }

  @override
  Future<void> markSent(Iterable<String> ids) async =>
      ids.forEach(items.remove);

  @override
  Future<void> markFailed(String id, String error) async {
    final item = items[id]!;
    items[id] = item.copyWith(
      status: SyncStatus.failed,
      attempts: item.attempts + 1,
      lastError: error,
    );
  }

  @override
  Future<void> retryFailed() async {
    for (final item in failed()) {
      items[item.id] = item.copyWith(status: SyncStatus.pending);
    }
  }

  @override
  Future<void> recoverInterrupted() async {
    for (final item in _byStatus(SyncStatus.sending)) {
      items[item.id] = item.copyWith(status: SyncStatus.pending);
    }
  }
}

class _FakeRemote implements SyncRemote {
  final rejected = <String>{};

  @override
  Future<void> sendBatch(String userId, List<SyncItem> items) async {
    if (items.any((item) => rejected.contains(item.entityId))) {
      throw const SyncRemoteException('permission-denied');
    }
  }
}

void main() {
  late _MemoryQueue queue;
  late _FakeRemote remote;

  setUp(() {
    queue = _MemoryQueue();
    remote = _FakeRemote();
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

import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hepatocheck_app/core/network/wifi_monitor.dart';
import 'package:hepatocheck_app/domain/entities/sync_item.dart';
import 'package:hepatocheck_app/domain/usecases/sync_pending_items.dart';
import 'package:hepatocheck_app/domain/entities/reduction_goal.dart';
import 'package:hepatocheck_app/presentation/providers/auth_providers.dart';
import 'package:hepatocheck_app/presentation/providers/consent_providers.dart';
import 'package:hepatocheck_app/presentation/providers/drink_providers.dart';
import 'package:hepatocheck_app/presentation/providers/exam_providers.dart';
import 'package:hepatocheck_app/presentation/providers/goal_providers.dart';
import 'package:hepatocheck_app/presentation/providers/sync_providers.dart';
import 'package:hepatocheck_app/presentation/widgets/auto_sync.dart';

import '../support/fake_auth_repository.dart';
import '../support/sync_fakes.dart';
import '../support/test_data.dart';

void main() {
  const delay = Duration(seconds: 2);
  late MemorySyncQueue queue;
  late FakeSyncRemote remote;
  late StreamController<List<ConnectivityResult>> network;
  late List<ConnectivityResult> current;
  late ProviderContainer container;
  late FakeAuthRepository auth;
  late MemorySyncConsentRepository consent;

  setUp(() {
    queue = MemorySyncQueue();
    remote = FakeSyncRemote();
    network = StreamController<List<ConnectivityResult>>.broadcast();
    current = [ConnectivityResult.mobile];
    auth = FakeAuthRepository();
    consent = MemorySyncConsentRepository();
    container = ProviderContainer(
      overrides: [
        syncQueueRepositoryProvider.overrideWithValue(queue),
        syncRemoteProvider.overrideWithValue(remote),
        authRepositoryProvider.overrideWithValue(auth),
        syncConsentRepositoryProvider.overrideWithValue(consent),
        goalRepositoryProvider.overrideWithValue(InMemoryGoalRepository()),
        cloudVaultProvider.overrideWithValue(FakeCloudVault()),
        currentUserIdProvider.overrideWithValue(() => 'usuario-1'),
        syncConsentProvider.overrideWithValue(true),
        drinkRepositoryProvider.overrideWithValue(MemoryDrinkRepository()),
        examRepositoryProvider.overrideWithValue(MemoryExamRepository()),
        wifiMonitorProvider.overrideWithValue(
          WifiMonitor(
            checkConnectivity: () async => current,
            connectivityChanges: network.stream,
          ),
        ),
      ],
    );
  });

  tearDown(() async {
    container.dispose();
    await network.close();
  });

  Future<void> pump(WidgetTester tester) async {
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const AutoSync(delay: delay, child: SizedBox()),
      ),
    );
    await tester.pump();
  }

  Future<void> setNetwork(
    WidgetTester tester,
    ConnectivityResult result,
  ) async {
    current = [result];
    network.add(current);
    await tester.pump();
  }

  Future<void> enqueue() => queue.enqueue(
    entityType: SyncEntityType.exam,
    entityId: 'exame-1',
    operation: SyncOperation.create,
    payload: const {'ast': 38},
  );

  testWidgets('envia a fila quando o Wi-Fi conecta', (tester) async {
    await enqueue();
    await pump(tester);
    await tester.pump(delay * 2);
    expect(remote.batches, 0);

    await setNetwork(tester, ConnectivityResult.wifi);
    await tester.pump(delay);
    await tester.pump();

    expect(remote.batches, 1);
    expect(queue.items, isEmpty);
  });

  testWidgets('não envia pelos dados móveis', (tester) async {
    await enqueue();
    await pump(tester);

    await setNetwork(tester, ConnectivityResult.mobile);
    await tester.pump(delay * 2);

    expect(remote.batches, 0);
    expect(queue.items, hasLength(1));
  });

  testWidgets('envia um novo registro feito enquanto está no Wi-Fi', (
    tester,
  ) async {
    current = [ConnectivityResult.wifi];
    await pump(tester);
    await tester.pump(delay);
    await tester.pump();
    expect(remote.batches, 0);

    await enqueue();
    await container.read(examsProvider.notifier).save(testExam(id: 'exame-1'));
    await tester.pump(delay);
    await tester.pump();

    expect(remote.batches, 1);
    expect(queue.items, isEmpty);
  });

  testWidgets('envia ao voltar para o app, se estiver no Wi-Fi', (
    tester,
  ) async {
    current = [ConnectivityResult.wifi];
    await pump(tester);
    await tester.pump(delay);
    await tester.pump();
    await enqueue();

    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pump(delay);
    await tester.pump();

    expect(remote.batches, 1);
    expect(queue.items, isEmpty);
  });

  testWidgets('várias alterações seguidas geram um só envio', (tester) async {
    current = [ConnectivityResult.wifi];
    await pump(tester);
    await tester.pump(delay);
    await tester.pump();
    await enqueue();

    for (var i = 0; i < 3; i++) {
      await container.read(examsProvider.notifier).save(testExam(id: 'e$i'));
      await tester.pump(const Duration(milliseconds: 500));
    }
    await tester.pump(delay);
    await tester.pump();

    expect(remote.batches, 1);
  });

  testWidgets('envia sozinho logo depois de entrar na conta', (tester) async {
    current = [ConnectivityResult.wifi];
    await pump(tester);
    await tester.pump(delay);
    await tester.pump();
    await enqueue();
    expect(remote.batches, 0);

    await auth.signIn(email: 'a@b.com', password: '123456');
    await tester.pump();
    await tester.pump(delay);
    await tester.pump();

    expect(remote.batches, 1);
    expect(queue.items, isEmpty);
  });

  testWidgets('envia sozinho logo depois de autorizar a sincronização', (
    tester,
  ) async {
    current = [ConnectivityResult.wifi];
    await pump(tester);
    await tester.pump(delay);
    await tester.pump();
    await enqueue();

    await container.read(syncConsentControllerProvider.notifier).grant();
    await tester.pump(delay);
    await tester.pump();

    expect(remote.batches, 1);
  });

  testWidgets('envia sozinho quando uma meta muda', (tester) async {
    current = [ConnectivityResult.wifi];
    await pump(tester);
    await tester.pump(delay);
    await tester.pump();
    await enqueue();

    final monday = DateTime(2026, 11, 16);
    await container
        .read(goalsProvider.notifier)
        .save(
          ReductionGoal(
            id: 'meta',
            type: GoalType.maxDrinksPerWeek,
            target: 7,
            startDate: monday,
            active: true,
            createdAt: monday,
            updatedAt: monday,
          ),
        );
    await tester.pump(delay);
    await tester.pump();

    expect(remote.batches, 1);
  });

  testWidgets('entrar na conta apaga a mensagem antiga de sem conta', (
    tester,
  ) async {
    await pump(tester);
    container.read(syncStatusProvider.notifier).state = const SyncStatusState(
      pending: [],
      failed: [],
      lastReport: SyncReport(skipped: SyncSkipReason.signedOut),
    );

    await auth.signIn(email: 'a@b.com', password: '123456');
    await tester.pump();

    expect(container.read(syncStatusProvider).lastReport, isNull);
  });
}

import 'dart:async';
import 'dart:io';
import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:hepatocheck_app/data/models/hive_registrar.g.dart';
import 'package:hepatocheck_app/data/sync/hive_sync_queue_repository.dart';
import 'package:hepatocheck_app/domain/entities/sync_item.dart';
import 'package:hepatocheck_app/domain/repositories/sync_remote.dart';
import 'package:hepatocheck_app/domain/usecases/sync_pending_items.dart';
import 'package:hive_ce/hive_ce.dart';

class _FakeRemote implements SyncRemote {
  final sentBatches = <List<SyncItem>>[];
  final rejectedEntityIds = <String>{};
  String errorCode = 'permission-denied';
  Completer<void>? gate;
  final started = Completer<void>();

  List<String> get sentEntityIds => [
    for (final batch in sentBatches)
      for (final item in batch) item.entityId,
  ];

  @override
  Future<void> sendBatch(String userId, List<SyncItem> items) async {
    if (!started.isCompleted) started.complete();
    await gate?.future;
    if (items.any((item) => rejectedEntityIds.contains(item.entityId))) {
      throw SyncRemoteException(errorCode);
    }
    sentBatches.add(items);
  }
}

void main() {
  late Directory dir;
  late HiveSyncQueueRepository queue;
  late _FakeRemote remote;
  late SyncPendingItems sync;
  late DateTime clock;
  var idCounter = 0;

  setUpAll(() => Hive.registerAdapters());

  setUp(() async {
    dir = await Directory.systemTemp.createTemp('sync_pending_items_test');
    Hive.init(dir.path);
    clock = DateTime(2026, 11, 16, 8);
    idCounter = 0;
    final box = await Hive.openBox<SyncItem>(
      'sync_queue',
      encryptionCipher: HiveAesCipher(
        List<int>.generate(32, (_) => Random.secure().nextInt(256)),
      ),
    );
    queue = HiveSyncQueueRepository(
      box,
      now: () => clock = clock.add(const Duration(seconds: 1)),
      newId: () => 'item-${++idCounter}',
    );
    remote = _FakeRemote();
    sync = SyncPendingItems(
      queue: queue,
      remote: remote,
      anonymize: (_, payload) => payload,
      batchSize: 5,
    );
  });

  tearDown(() async {
    await Hive.close();
    await dir.delete(recursive: true);
  });

  Future<void> enqueueExams(int count) async {
    for (var i = 1; i <= count; i++) {
      await queue.enqueue(
        entityType: SyncEntityType.exam,
        entityId: 'exame-$i',
        operation: SyncOperation.create,
        payload: {'ast': 30 + i},
      );
    }
  }

  Future<SyncReport> run() =>
      sync(userId: 'usuario-1', hasConsent: true, isOnWifi: true);

  test('teste 4: falha parcial envia 5, guarda 2 com erro e recupera '
      'na nova tentativa', () async {
    await enqueueExams(7);
    remote.rejectedEntityIds.addAll({'exame-6', 'exame-7'});

    final first = await run();

    expect(first.sent, 5);
    expect(first.failed, 2);
    expect(remote.sentEntityIds, [
      'exame-1',
      'exame-2',
      'exame-3',
      'exame-4',
      'exame-5',
    ]);
    expect(queue.pending(), isEmpty);
    final failed = queue.failed();
    expect(failed.map((item) => item.entityId), ['exame-6', 'exame-7']);
    expect(failed.every((item) => item.attempts == 1), isTrue);
    expect(
      failed.every((item) => item.lastError == 'permission-denied'),
      isTrue,
    );

    remote.rejectedEntityIds.clear();
    await queue.retryFailed();
    final second = await run();

    expect(second.sent, 2);
    expect(second.failed, 0);
    expect(queue.pending(), isEmpty);
    expect(queue.failed(), isEmpty);
    expect(remote.sentEntityIds, hasLength(7));
  });

  test('envia em lotes do tamanho configurado, na ordem da fila', () async {
    await enqueueExams(12);

    final report = await run();

    expect(report.sent, 12);
    expect(remote.sentBatches.map((batch) => batch.length), [5, 5, 2]);
    expect(remote.sentEntityIds.first, 'exame-1');
    expect(remote.sentEntityIds.last, 'exame-12');
  });

  test('falha repetida soma as tentativas', () async {
    await enqueueExams(1);
    remote.rejectedEntityIds.add('exame-1');
    remote.errorCode = 'unavailable';

    await run();
    await queue.retryFailed();
    await run();

    final failed = queue.failed().single;
    expect(failed.attempts, 2);
    expect(failed.lastError, 'unavailable');
  });

  test('erro desconhecido também fica registrado na fila', () async {
    await enqueueExams(1);
    final failingSync = SyncPendingItems(
      queue: queue,
      remote: _ThrowingRemote(),
      anonymize: (_, payload) => payload,
    );

    final report = await failingSync(
      userId: 'usuario-1',
      hasConsent: true,
      isOnWifi: true,
    );

    expect(report.failed, 1);
    expect(queue.failed().single.lastError, SyncPendingItems.unknownError);
  });

  test('não envia sem conta, sem consentimento ou fora do Wi-Fi', () async {
    await enqueueExams(2);

    final signedOut = await sync(
      userId: null,
      hasConsent: true,
      isOnWifi: true,
    );
    final noConsent = await sync(
      userId: 'usuario-1',
      hasConsent: false,
      isOnWifi: true,
    );
    final noWifi = await sync(
      userId: 'usuario-1',
      hasConsent: true,
      isOnWifi: false,
    );

    expect(signedOut.skipped, SyncSkipReason.signedOut);
    expect(noConsent.skipped, SyncSkipReason.noConsent);
    expect(noWifi.skipped, SyncSkipReason.noWifi);
    expect(remote.sentBatches, isEmpty);
    expect(queue.pending(), hasLength(2));
  });

  test('reenvia itens que ficaram interrompidos no meio do envio', () async {
    await enqueueExams(2);
    await queue.markSending([queue.pending().first.id]);

    final report = await run();

    expect(report.sent, 2);
    expect(queue.pending(), isEmpty);
  });

  test(
    'não inicia um segundo envio enquanto o primeiro está em andamento',
    () async {
      await enqueueExams(1);
      remote.gate = Completer<void>();

      final first = run();
      final second = await run();
      remote.gate!.complete();

      expect(second.skipped, SyncSkipReason.alreadyRunning);
      expect((await first).sent, 1);
      expect(remote.sentBatches, hasLength(1));
    },
  );

  test('anonimiza o conteúdo enviado sem alterar a fila local', () async {
    await enqueueExams(1);
    await queue.enqueue(
      entityType: SyncEntityType.drink,
      entityId: 'drinque-1',
      operation: SyncOperation.update,
      payload: {'quantity': 1},
    );
    final anonymizing = SyncPendingItems(
      queue: queue,
      remote: remote,
      anonymize: (type, payload) => {'type': type.name, 'anon': true},
    );
    await queue.enqueue(
      entityType: SyncEntityType.drink,
      entityId: 'drinque-1',
      operation: SyncOperation.delete,
      payload: const {},
    );

    await anonymizing(userId: 'usuario-1', hasConsent: true, isOnWifi: true);

    final sent = remote.sentBatches.single;
    expect(sent.first.payload, {'type': 'exam', 'anon': true});
    expect(sent.last.operation, SyncOperation.delete);
    expect(sent.last.payload, isEmpty);
  });

  test('alteração feita durante um envio que falha não é sobrescrita pela '
      'versão antiga', () async {
    await enqueueExams(1);
    remote.rejectedEntityIds.add('exame-1');
    remote.gate = Completer<void>();

    final running = run();
    await remote.started.future;
    await queue.enqueue(
      entityType: SyncEntityType.exam,
      entityId: 'exame-1',
      operation: SyncOperation.update,
      payload: {'ast': 99},
    );
    remote.gate!.complete();
    await running;

    expect(queue.failed(), isEmpty);
    expect(queue.pending().single.payload, {'ast': 99});
  });
}

class _ThrowingRemote implements SyncRemote {
  @override
  Future<void> sendBatch(String userId, List<SyncItem> items) =>
      Future.error(StateError('sem rede'));
}

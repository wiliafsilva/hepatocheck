import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:hepatocheck_app/data/models/hive_registrar.g.dart';
import 'package:hepatocheck_app/data/sync/hive_sync_queue_repository.dart';
import 'package:hepatocheck_app/domain/entities/sync_item.dart';
import 'package:hive_ce/hive_ce.dart';

List<int> _newKey() =>
    List<int>.generate(32, (_) => Random.secure().nextInt(256));

void main() {
  late Directory dir;
  late List<int> key;
  late Box<SyncItem> box;
  late HiveSyncQueueRepository queue;
  late DateTime clock;
  var idCounter = 0;

  setUpAll(() => Hive.registerAdapters());

  Future<Box<SyncItem>> openBox(List<int> withKey) => Hive.openBox<SyncItem>(
    'sync_queue',
    encryptionCipher: HiveAesCipher(withKey),
  );

  HiveSyncQueueRepository newQueue(Box<SyncItem> target) =>
      HiveSyncQueueRepository(
        target,
        now: () => clock = clock.add(const Duration(seconds: 1)),
        newId: () => 'item-${++idCounter}',
      );

  setUp(() async {
    dir = await Directory.systemTemp.createTemp('sync_queue_test');
    Hive.init(dir.path);
    key = _newKey();
    clock = DateTime(2026, 11, 9, 8);
    idCounter = 0;
    box = await openBox(key);
    queue = newQueue(box);
  });

  tearDown(() async {
    await Hive.close();
    await dir.delete(recursive: true);
  });

  test('enfileira uma alteração nova como pendente', () async {
    await queue.enqueue(
      entityType: SyncEntityType.exam,
      entityId: 'exame-1',
      operation: SyncOperation.create,
      payload: {'ast': 38},
    );

    final pending = queue.pending();
    expect(pending, hasLength(1));
    expect(pending.single.entityId, 'exame-1');
    expect(pending.single.operation, SyncOperation.create);
    expect(pending.single.status, SyncStatus.pending);
    expect(pending.single.payload, {'ast': 38});
  });

  test(
    'várias edições do mesmo registro viram um só item com a última versão',
    () async {
      await queue.enqueue(
        entityType: SyncEntityType.drink,
        entityId: 'drinque-1',
        operation: SyncOperation.create,
        payload: {'quantity': 1},
      );
      await queue.enqueue(
        entityType: SyncEntityType.drink,
        entityId: 'drinque-1',
        operation: SyncOperation.update,
        payload: {'quantity': 2},
      );
      await queue.enqueue(
        entityType: SyncEntityType.drink,
        entityId: 'drinque-1',
        operation: SyncOperation.update,
        payload: {'quantity': 3},
      );

      final pending = queue.pending();
      expect(pending, hasLength(1));
      expect(pending.single.operation, SyncOperation.create);
      expect(pending.single.payload, {'quantity': 3});
    },
  );

  test('criar e excluir antes de sincronizar remove o item da fila', () async {
    await queue.enqueue(
      entityType: SyncEntityType.drink,
      entityId: 'drinque-1',
      operation: SyncOperation.create,
      payload: {'quantity': 1},
    );
    await queue.enqueue(
      entityType: SyncEntityType.drink,
      entityId: 'drinque-1',
      operation: SyncOperation.delete,
      payload: const {},
    );

    expect(queue.pending(), isEmpty);
    expect(box.isEmpty, isTrue);
  });

  test(
    'editar e depois excluir um registro já sincronizado envia só a exclusão',
    () async {
      await queue.enqueue(
        entityType: SyncEntityType.exam,
        entityId: 'exame-1',
        operation: SyncOperation.update,
        payload: {'ast': 40},
      );
      await queue.enqueue(
        entityType: SyncEntityType.exam,
        entityId: 'exame-1',
        operation: SyncOperation.delete,
        payload: const {},
      );

      expect(queue.pending().single.operation, SyncOperation.delete);
    },
  );

  test('alteração feita durante o envio gera um item separado', () async {
    await queue.enqueue(
      entityType: SyncEntityType.exam,
      entityId: 'exame-1',
      operation: SyncOperation.create,
      payload: {'ast': 38},
    );
    await queue.markSending([queue.pending().single.id]);
    await queue.enqueue(
      entityType: SyncEntityType.exam,
      entityId: 'exame-1',
      operation: SyncOperation.update,
      payload: {'ast': 45},
    );

    expect(box.length, 2);
    expect(queue.pending().single.payload, {'ast': 45});
  });

  test('itens enviados saem da fila e falhas ficam registradas', () async {
    for (final id in ['a', 'b', 'c']) {
      await queue.enqueue(
        entityType: SyncEntityType.goal,
        entityId: id,
        operation: SyncOperation.create,
        payload: {'target': 3},
      );
    }
    final ids = queue.pending().map((item) => item.id).toList();
    await queue.markSending(ids);
    await queue.markSent(ids.take(2));
    await queue.markFailed(ids.last, 'permission-denied');

    expect(queue.pending(), isEmpty);
    final failed = queue.failed().single;
    expect(failed.id, ids.last);
    expect(failed.attempts, 1);
    expect(failed.lastError, 'permission-denied');

    await queue.retryFailed();
    expect(queue.failed(), isEmpty);
    expect(queue.pending().single.id, ids.last);
  });

  test('itens interrompidos durante o envio voltam para pendente', () async {
    await queue.enqueue(
      entityType: SyncEntityType.exam,
      entityId: 'exame-1',
      operation: SyncOperation.create,
      payload: {'ast': 38},
    );
    await queue.markSending([queue.pending().single.id]);
    expect(queue.pending(), isEmpty);

    await queue.recoverInterrupted();

    expect(queue.pending(), hasLength(1));
  });

  test('pendentes saem na ordem em que foram criados', () async {
    for (final id in ['primeiro', 'segundo', 'terceiro']) {
      await queue.enqueue(
        entityType: SyncEntityType.drink,
        entityId: id,
        operation: SyncOperation.create,
        payload: const {},
      );
    }

    expect(queue.pending().map((item) => item.entityId), [
      'primeiro',
      'segundo',
      'terceiro',
    ]);
  });

  test('a fila é persistida criptografada', () async {
    await queue.enqueue(
      entityType: SyncEntityType.exam,
      entityId: 'exame-1',
      operation: SyncOperation.create,
      payload: {'observacao': 'conteudo-secreto-da-fila'},
    );
    await Hive.close();

    final raw = latin1.decode(
      await File('${dir.path}/sync_queue.hive').readAsBytes(),
    );
    expect(raw.contains('conteudo-secreto-da-fila'), isFalse);
    expect(raw.contains('exame-1'), isFalse);

    final reopened = newQueue(await openBox(key));
    expect(reopened.pending().single.payload, {
      'observacao': 'conteudo-secreto-da-fila',
    });
    await Hive.close();

    await expectLater(openBox(_newKey()), throwsA(isA<HiveError>()));
  });
}

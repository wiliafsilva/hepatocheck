import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:hepatocheck_app/data/models/hive_registrar.g.dart';
import 'package:hepatocheck_app/data/repositories/hive_exam_repository.dart';
import 'package:hepatocheck_app/data/sync/hive_sync_queue_repository.dart';
import 'package:hepatocheck_app/domain/entities/lab_exam.dart';
import 'package:hepatocheck_app/domain/entities/sync_item.dart';
import 'package:hive_ce/hive_ce.dart';

void main() {
  late Directory dir;
  late List<int> key;
  late HiveSyncQueueRepository syncQueue;
  late HiveExamRepository repository;
  var counter = 0;

  setUpAll(() => Hive.registerAdapters());

  Future<HiveSyncQueueRepository> openQueue() async => HiveSyncQueueRepository(
    await Hive.openBox<SyncItem>(
      'sync_queue',
      encryptionCipher: HiveAesCipher(key),
    ),
    newId: () => 'fila-${++counter}',
  );

  setUp(() async {
    dir = await Directory.systemTemp.createTemp('exam_repository_test');
    Hive.init(dir.path);
    key = List<int>.generate(32, (_) => Random.secure().nextInt(256));
    syncQueue = await openQueue();
    repository = HiveExamRepository(
      await Hive.openBox<LabExam>(
        'exams',
        encryptionCipher: HiveAesCipher(key),
      ),
      syncQueue,
    );
  });

  tearDown(() async {
    await Hive.close();
    await dir.delete(recursive: true);
  });

  LabExam exam(String id, {double ast = 38}) {
    final date = DateTime(2026, 11, 10, 9);
    return LabExam(
      id: id,
      examDate: date,
      age: 45,
      ast: ast,
      alt: 40,
      platelets: 220,
      createdAt: date,
      updatedAt: date,
    );
  }

  Future<void> markAllSent() async {
    final ids = [for (final item in syncQueue.pending()) item.id];
    await syncQueue.markSending(ids);
    await syncQueue.markSent(ids);
  }

  test('salvar coloca o exame na fila com os campos do Firestore', () async {
    await repository.save(exam('e1'));

    final item = syncQueue.pending().single;
    expect(item.entityType, SyncEntityType.exam);
    expect(item.entityId, 'e1');
    expect(item.operation, SyncOperation.create);
    expect(item.payload, {
      'examDate': DateTime(2026, 11, 10, 9).toUtc(),
      'age': 45,
      'ast': 38.0,
      'alt': 40.0,
      'platelets': 220.0,
      'createdAt': DateTime(2026, 11, 10, 9).toUtc(),
      'updatedAt': DateTime(2026, 11, 10, 9).toUtc(),
    });
  });

  test('editar um exame já sincronizado gera atualização', () async {
    await repository.save(exam('e1'));
    await markAllSent();

    await repository.save(exam('e1', ast: 50));

    final item = syncQueue.pending().single;
    expect(item.operation, SyncOperation.update);
    expect(item.payload['ast'], 50.0);
  });

  test('excluir um exame já sincronizado gera exclusão', () async {
    await repository.save(exam('e1'));
    await markAllSent();

    await repository.delete('e1');

    expect(repository.getAll(), isEmpty);
    expect(syncQueue.pending().single.operation, SyncOperation.delete);
  });

  test('excluir um exame inexistente não entra na fila', () async {
    await repository.delete('nao-existe');
    expect(syncQueue.pending(), isEmpty);
  });

  test(
    'a fila guarda as datas e continua criptografada após reabrir',
    () async {
      await repository.save(exam('exame-secreto', ast: 777));
      await Hive.close();

      final raw = latin1.decode(
        await File('${dir.path}/sync_queue.hive').readAsBytes(),
      );
      expect(raw.contains('exame-secreto'), isFalse);
      expect(raw.contains('examDate'), isFalse);

      final reopened = await openQueue();
      final payload = reopened.pending().single.payload;
      expect(payload['examDate'], DateTime(2026, 11, 10, 9).toUtc());
      expect(payload['ast'], 777.0);
    },
  );
}

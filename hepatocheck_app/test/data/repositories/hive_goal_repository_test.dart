import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce/hive.dart';
import 'package:hepatocheck_app/data/repositories/hive_goal_repository.dart';
import 'package:hepatocheck_app/domain/entities/reduction_goal.dart';
import 'package:hepatocheck_app/domain/entities/sync_item.dart';

import '../../support/sync_fakes.dart';

void main() {
  late Directory directory;
  final key = List<int>.generate(32, (i) => i);
  setUp(() async {
    directory = await Directory.systemTemp.createTemp('goals-test');
    Hive.init(directory.path);
  });
  tearDown(() async {
    await Hive.close();
    await directory.delete(recursive: true);
  });
  test('aceita 0 e 100 drinques e rejeita valores fora do limite', () async {
    final box = await Hive.openBox<String>('limits');
    final repository = HiveGoalRepository(box, MemorySyncQueue());
    final now = DateTime(2026, 11, 15);
    final goal = ReductionGoal(
      id: 'limit',
      type: GoalType.maxDrinksPerWeek,
      target: 0,
      startDate: now,
      active: true,
      createdAt: now,
      updatedAt: now,
    );
    for (final target in [0, 100]) {
      await repository.save(goal.copyWith(target: target));
      expect(repository.getAll().single.target, target);
    }
    for (final target in [-1, 101]) {
      await expectLater(
        repository.save(goal.copyWith(target: target)),
        throwsArgumentError,
      );
    }
  });
  test('CRUD criptografado preserva metas ao reabrir', () async {
    final now = DateTime(2026, 11, 9);
    final goal = ReductionGoal(
      id: 'private-goal',
      type: GoalType.maxDrinksPerWeek,
      target: 8,
      startDate: now,
      active: true,
      createdAt: now,
      updatedAt: now,
    );
    var box = await Hive.openBox<String>(
      'goals',
      encryptionCipher: HiveAesCipher(key),
    );
    var repository = HiveGoalRepository(box, MemorySyncQueue());
    await repository.save(goal);
    await repository.save(goal.copyWith(target: 4));
    await box.close();
    final raw = latin1.decode(
      await File('${directory.path}/goals.hive').readAsBytes(),
    );
    expect(raw.contains('maxDrinksPerWeek'), isFalse);
    // A chave da caixa é um ID opaco. O conteúdo deve permanecer cifrado.
    expect(raw.contains('"target":4'), isFalse);
    box = await Hive.openBox<String>(
      'goals',
      encryptionCipher: HiveAesCipher(key),
    );
    repository = HiveGoalRepository(box, MemorySyncQueue());
    expect(repository.getAll().single.target, 4);
    await box.close();
    await expectLater(
      Hive.openBox<String>(
        'goals',
        encryptionCipher: HiveAesCipher(List.filled(32, 77)),
      ),
      throwsA(isA<HiveError>()),
    );
    box = await Hive.openBox<String>(
      'goals',
      encryptionCipher: HiveAesCipher(key),
    );
    repository = HiveGoalRepository(box, MemorySyncQueue());
    expect(repository.getAll().single.target, 4);
    await repository.delete(goal.id);
    expect(repository.getAll(), isEmpty);
  });

  group('fila de sincronização', () {
    late MemorySyncQueue queue;
    late HiveGoalRepository repository;
    final now = DateTime(2026, 11, 16, 10);
    final goal = ReductionGoal(
      id: 'meta-1',
      type: GoalType.alcoholFreeDaysPerWeek,
      target: 3,
      startDate: now,
      active: true,
      createdAt: now,
      updatedAt: now,
    );

    setUp(() async {
      queue = MemorySyncQueue();
      repository = HiveGoalRepository(
        await Hive.openBox<String>('sync-goals'),
        queue,
      );
    });

    test('criar coloca a meta na fila no formato do Firestore', () async {
      await repository.save(goal);

      final item = queue.pending().single;
      expect(item.entityType, SyncEntityType.goal);
      expect(item.entityId, 'meta-1');
      expect(item.operation, SyncOperation.create);
      expect(item.payload, {
        'type': 'alcoholFreeDaysPerWeek',
        'target': 3,
        'startDate': now.toUtc(),
        'endDate': null,
        'active': true,
        'createdAt': now.toUtc(),
        'updatedAt': now.toUtc(),
      });
    });

    test('editar e excluir também entram na fila', () async {
      await repository.save(goal);
      await repository.save(goal.copyWith(target: 5));
      await repository.delete('meta-1');

      expect(queue.items.values.map((item) => item.operation), [
        SyncOperation.create,
        SyncOperation.update,
        SyncOperation.delete,
      ]);
      expect(queue.items.values.last.payload, isEmpty);
    });

    test('meta inválida ou exclusão inexistente não entram na fila', () async {
      await expectLater(
        repository.save(goal.copyWith(target: 8)),
        throwsArgumentError,
      );
      await repository.delete('nao-existe');

      expect(queue.items, isEmpty);
    });
  });
}

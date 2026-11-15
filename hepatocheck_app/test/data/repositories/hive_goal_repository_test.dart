import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce/hive.dart';
import 'package:hepatocheck_app/data/repositories/hive_goal_repository.dart';
import 'package:hepatocheck_app/domain/entities/reduction_goal.dart';

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
    final repository = HiveGoalRepository(box);
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
    var repository = HiveGoalRepository(box);
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
    repository = HiveGoalRepository(box);
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
    repository = HiveGoalRepository(box);
    expect(repository.getAll().single.target, 4);
    await repository.delete(goal.id);
    expect(repository.getAll(), isEmpty);
  });
}

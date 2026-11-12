import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hepatocheck_app/data/datasources/local/hive_local_data_eraser.dart';
import 'package:hive_ce/hive_ce.dart';

void main() {
  late Directory dir;

  setUp(() async {
    dir = await Directory.systemTemp.createTemp('local_data_eraser_test');
    Hive.init(dir.path);
  });

  tearDown(() async {
    await Hive.close();
    await dir.delete(recursive: true);
  });

  test(
    'apaga o conteúdo de todas as caixas e elas continuam abertas',
    () async {
      final drinks = await Hive.openBox<String>('drinks');
      final exams = await Hive.openBox<String>('exams');
      final queue = await Hive.openBox<String>('sync_queue');
      await drinks.putAll({'a': 'drinque', 'b': 'drinque'});
      await exams.put('e', 'exame');
      await queue.put('q', 'pendente');

      await HiveLocalDataEraser([drinks, exams, queue]).eraseAll();

      expect(drinks.isEmpty, isTrue);
      expect(exams.isEmpty, isTrue);
      expect(queue.isEmpty, isTrue);
      expect(drinks.isOpen, isTrue);

      await drinks.put('c', 'novo');
      expect(drinks.length, 1);
    },
  );

  test('os dados apagados não voltam ao reabrir', () async {
    final drinks = await Hive.openBox<String>('drinks');
    await drinks.put('a', 'drinque');

    await HiveLocalDataEraser([drinks]).eraseAll();
    await Hive.close();

    expect((await Hive.openBox<String>('drinks')).isEmpty, isTrue);
  });
}

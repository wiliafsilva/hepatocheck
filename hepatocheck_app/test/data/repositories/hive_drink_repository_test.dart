import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:hepatocheck_app/data/models/hive_registrar.g.dart';
import 'package:hepatocheck_app/data/repositories/hive_audit_log_repository.dart';
import 'package:hepatocheck_app/data/repositories/hive_drink_repository.dart';
import 'package:hepatocheck_app/domain/entities/audit_entry.dart';
import 'package:hepatocheck_app/domain/entities/drink_entry.dart';
import 'package:hepatocheck_app/domain/entities/drink_type.dart';
import 'package:hive_ce/hive_ce.dart';

void main() {
  late Directory dir;
  late List<int> key;
  late Box<DrinkEntry> drinksBox;
  late Box<AuditEntry> auditBox;
  late HiveAuditLogRepository auditLog;
  late HiveDrinkRepository repository;
  var clock = DateTime(2026, 11, 11, 20);

  setUpAll(() => Hive.registerAdapters());

  setUp(() async {
    dir = await Directory.systemTemp.createTemp('drink_repository_test');
    Hive.init(dir.path);
    key = List<int>.generate(32, (_) => Random.secure().nextInt(256));
    drinksBox = await Hive.openBox<DrinkEntry>(
      'drinks',
      encryptionCipher: HiveAesCipher(key),
    );
    auditBox = await Hive.openBox<AuditEntry>(
      'audit_log',
      encryptionCipher: HiveAesCipher(key),
    );
    clock = DateTime(2026, 11, 11, 20);
    var counter = 0;
    auditLog = HiveAuditLogRepository(
      auditBox,
      now: () => clock = clock.add(const Duration(minutes: 1)),
      newId: () => 'log-${++counter}',
    );
    repository = HiveDrinkRepository(drinksBox, auditLog);
  });

  tearDown(() async {
    await Hive.close();
    await dir.delete(recursive: true);
  });

  DrinkEntry drink(String id, {int quantity = 1, DateTime? consumedAt}) {
    final at = consumedAt ?? DateTime(2026, 11, 11, 19);
    return DrinkEntry(
      id: id,
      type: DrinkType.beer,
      volumeMl: 350,
      alcoholPercent: 5,
      quantity: quantity,
      consumedAt: at,
      createdAt: at,
      updatedAt: at,
    );
  }

  test('salva, lista do mais recente para o mais antigo e exclui', () async {
    await repository.save(drink('a', consumedAt: DateTime(2026, 11, 10)));
    await repository.save(drink('b', consumedAt: DateTime(2026, 11, 11)));

    expect(repository.getAll().map((entry) => entry.id), ['b', 'a']);
    expect(repository.getById('a')?.quantity, 1);

    await repository.delete('a');
    expect(repository.getAll().map((entry) => entry.id), ['b']);
  });

  test('registra criação, edição e exclusão no log', () async {
    await repository.save(drink('a'));
    await repository.save(drink('a', quantity: 2));
    await repository.delete('a');

    final log = auditLog.entries();
    expect(log.map((entry) => entry.operation), [
      AuditOperation.create,
      AuditOperation.update,
      AuditOperation.delete,
    ]);
    expect(log.every((entry) => entry.entityId == 'a'), isTrue);
  });

  test('excluir um registro inexistente não gera entrada no log', () async {
    await repository.delete('nao-existe');
    expect(auditLog.entries(), isEmpty);
  });

  test('o log guarda só hashes, nunca o conteúdo do drinque', () async {
    await repository.save(drink('a', quantity: 7));

    final entry = auditLog.entries().single;
    expect(
      entry.contentHash,
      HiveAuditLogRepository.hashContent(
        HiveDrinkRepository.auditContent(drink('a', quantity: 7)),
      ),
    );
    expect(entry.contentHash, hasLength(64));
    final stored = [
      entry.id,
      entry.operation.name,
      entry.entityId,
      entry.contentHash,
      entry.previousHash,
    ].join(' ');
    for (final secret in ['beer', '350', 'quantity', 'consumedAt']) {
      expect(stored.contains(secret), isFalse, reason: secret);
    }
  });

  test('edições diferentes geram hashes de conteúdo diferentes', () async {
    await repository.save(drink('a'));
    await repository.save(drink('a', quantity: 2));

    final log = auditLog.entries();
    expect(log[0].contentHash, isNot(log[1].contentHash));
  });

  test('as entradas ficam encadeadas e a cadeia é válida', () async {
    await repository.save(drink('a'));
    await repository.save(drink('b'));
    await repository.delete('a');

    final log = auditLog.entries();
    expect(log.first.previousHash, HiveAuditLogRepository.genesisHash);
    expect(log[1].previousHash, HiveAuditLogRepository.chainHash(log[0]));
    expect(log[2].previousHash, HiveAuditLogRepository.chainHash(log[1]));
    expect(auditLog.verifyChain(), isTrue);
  });

  test('a cadeia acusa entrada removida ou adulterada', () async {
    await repository.save(drink('a'));
    await repository.save(drink('b'));
    await repository.save(drink('c'));

    final original = auditBox.getAt(1)!;
    await auditBox.putAt(
      1,
      AuditEntry(
        id: original.id,
        operation: AuditOperation.delete,
        entityId: original.entityId,
        timestamp: original.timestamp,
        contentHash: original.contentHash,
        previousHash: original.previousHash,
      ),
    );
    expect(auditLog.verifyChain(), isFalse);

    await auditBox.putAt(1, original);
    expect(auditLog.verifyChain(), isTrue);

    await auditBox.deleteAt(1);
    expect(auditLog.verifyChain(), isFalse);
  });

  test('o diário e o log ficam criptografados no disco', () async {
    await repository.save(drink('drinque-secreto', quantity: 9));
    await Hive.close();

    for (final name in ['drinks', 'audit_log']) {
      final raw = latin1.decode(
        await File('${dir.path}/$name.hive').readAsBytes(),
      );
      expect(raw.contains('beer'), isFalse, reason: name);
    }
    final rawLog = latin1.decode(
      await File('${dir.path}/audit_log.hive').readAsBytes(),
    );
    expect(rawLog.contains('drinque-secreto'), isFalse);
  });
}

import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:hepatocheck_app/data/models/hive_registrar.g.dart';
import 'package:hepatocheck_app/domain/entities/audit_entry.dart';
import 'package:hive_ce/hive_ce.dart';

List<int> _newKey() =>
    List<int>.generate(32, (_) => Random.secure().nextInt(256));

void main() {
  late Directory directory;
  late List<int> key;

  setUpAll(() => Hive.registerAdapters());

  setUp(() async {
    directory = await Directory.systemTemp.createTemp('audit_log_encryption');
    Hive.init(directory.path);
    key = _newKey();
  });

  tearDown(() async {
    await Hive.close();
    await directory.delete(recursive: true);
  });

  test(
    'protege o log e preserva os registros ao reabrir com a chave',
    () async {
      final encrypted = await Hive.openBox<AuditEntry>(
        'audit_log',
        encryptionCipher: HiveAesCipher(key),
      );
      final entry = AuditEntry(
        id: 'audit-1',
        operation: AuditOperation.update,
        entityId: 'drink-1',
        timestamp: DateTime(2026, 11, 10),
        contentHash: 'hash-conteudo-sensivel',
        previousHash: 'hash-anterior',
      );
      await encrypted.put(entry.id, entry);
      await Hive.close();

      final raw = latin1.decode(
        await File('${directory.path}/audit_log.hive').readAsBytes(),
      );
      expect(raw.contains('hash-conteudo-sensivel'), isFalse);
      expect(raw.contains('drink-1'), isFalse);

      final reopened = await Hive.openBox<AuditEntry>(
        'audit_log',
        encryptionCipher: HiveAesCipher(key),
      );
      expect(reopened.get('audit-1')?.contentHash, entry.contentHash);
      await Hive.close();

      await expectLater(
        Hive.openBox<AuditEntry>(
          'audit_log',
          encryptionCipher: HiveAesCipher(_newKey()),
        ),
        throwsA(isA<HiveError>()),
      );
    },
  );
}

import 'dart:collection';
import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:hive_ce/hive.dart';
import 'package:uuid/uuid.dart';

import '../../domain/entities/audit_entry.dart';
import '../../domain/repositories/audit_log_repository.dart';

class HiveAuditLogRepository implements AuditLogRepository {
  HiveAuditLogRepository(
    this._box, {
    DateTime Function()? now,
    String Function()? newId,
  }) : _now = now ?? DateTime.now,
       _newId = newId ?? const Uuid().v4;

  static final genesisHash = '0' * 64;

  final Box<AuditEntry> _box;
  final DateTime Function() _now;
  final String Function() _newId;

  @override
  Future<AuditEntry> record({
    required AuditOperation operation,
    required String entityId,
    Map<String, Object?>? content,
  }) async {
    final last = _box.isEmpty ? null : _box.getAt(_box.length - 1);
    final entry = AuditEntry(
      id: _newId(),
      operation: operation,
      entityId: entityId,
      timestamp: _now(),
      contentHash: hashContent(content),
      previousHash: last == null ? genesisHash : chainHash(last),
    );
    await _box.add(entry);
    return entry;
  }

  @override
  List<AuditEntry> entries() => _box.values.toList();

  @override
  bool verifyChain() {
    var expectedPrevious = genesisHash;
    for (final entry in _box.values) {
      if (entry.previousHash != expectedPrevious) return false;
      expectedPrevious = chainHash(entry);
    }
    return true;
  }

  static String hashContent(Map<String, Object?>? content) {
    final canonical = content == null
        ? 'deleted'
        : jsonEncode(SplayTreeMap<String, Object?>.of(content));
    return sha256.convert(utf8.encode(canonical)).toString();
  }

  static String chainHash(AuditEntry entry) => sha256
      .convert(
        utf8.encode(
          [
            entry.previousHash,
            entry.operation.name,
            entry.entityId,
            entry.timestamp.toUtc().toIso8601String(),
            entry.contentHash,
          ].join('|'),
        ),
      )
      .toString();
}

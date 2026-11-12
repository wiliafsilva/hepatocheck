import 'package:hive_ce/hive.dart';

import '../../domain/entities/audit_entry.dart';
import '../../domain/entities/drink_entry.dart';
import '../../domain/entities/sync_item.dart';
import '../../domain/repositories/audit_log_repository.dart';
import '../../domain/repositories/drink_repository.dart';
import '../../domain/repositories/sync_queue_repository.dart';
import '../models/firestore_mappers.dart';

class HiveDrinkRepository implements DrinkRepository {
  HiveDrinkRepository(this._box, this._auditLog, this._syncQueue);

  final Box<DrinkEntry> _box;
  final AuditLogRepository _auditLog;
  final SyncQueueRepository _syncQueue;

  @override
  List<DrinkEntry> getAll() {
    final drinks = _box.values.toList()
      ..sort((a, b) {
        final byDate = b.consumedAt.compareTo(a.consumedAt);
        if (byDate != 0) return byDate;
        return b.createdAt.compareTo(a.createdAt);
      });
    return drinks;
  }

  @override
  DrinkEntry? getById(String id) => _box.get(id);

  @override
  Future<void> save(DrinkEntry entry) async {
    final isNew = !_box.containsKey(entry.id);
    await _box.put(entry.id, entry);
    await _auditLog.record(
      operation: isNew ? AuditOperation.create : AuditOperation.update,
      entityId: entry.id,
      content: auditContent(entry),
    );
    await _syncQueue.enqueue(
      entityType: SyncEntityType.drink,
      entityId: entry.id,
      operation: isNew ? SyncOperation.create : SyncOperation.update,
      payload: FirestoreMappers.drinkToFirestore(entry),
    );
  }

  @override
  Future<void> delete(String id) async {
    if (!_box.containsKey(id)) return;
    await _box.delete(id);
    await _auditLog.record(operation: AuditOperation.delete, entityId: id);
    await _syncQueue.enqueue(
      entityType: SyncEntityType.drink,
      entityId: id,
      operation: SyncOperation.delete,
      payload: const {},
    );
  }

  static Map<String, Object?> auditContent(DrinkEntry entry) => {
    'type': entry.type.name,
    'volumeMl': entry.volumeMl,
    'alcoholPercent': entry.alcoholPercent,
    'quantity': entry.quantity,
    'consumedAt': entry.consumedAt.toUtc().toIso8601String(),
  };
}

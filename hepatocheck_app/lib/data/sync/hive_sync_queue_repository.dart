import 'package:hive_ce/hive.dart';
import 'package:uuid/uuid.dart';

import '../../domain/entities/sync_item.dart';
import '../../domain/repositories/sync_queue_repository.dart';

class HiveSyncQueueRepository implements SyncQueueRepository {
  HiveSyncQueueRepository(
    this._box, {
    DateTime Function()? now,
    String Function()? newId,
  }) : _now = now ?? DateTime.now,
       _newId = newId ?? const Uuid().v4;

  final Box<SyncItem> _box;
  final DateTime Function() _now;
  final String Function() _newId;

  @override
  Future<void> enqueue({
    required SyncEntityType entityType,
    required String entityId,
    required SyncOperation operation,
    required Map<String, dynamic> payload,
  }) async {
    final waiting = _box.values.where(
      (item) =>
          item.entityType == entityType &&
          item.entityId == entityId &&
          item.status != SyncStatus.sending,
    );
    final previous = waiting.isEmpty ? null : waiting.first;

    if (previous == null) {
      final item = SyncItem(
        id: _newId(),
        entityType: entityType,
        entityId: entityId,
        operation: operation,
        payload: payload,
        createdAt: _now(),
      );
      await _box.put(item.id, item);
      return;
    }

    if (previous.operation == SyncOperation.create &&
        operation == SyncOperation.delete) {
      await _box.delete(previous.id);
      return;
    }

    final mergedOperation =
        previous.operation == SyncOperation.create &&
            operation == SyncOperation.update
        ? SyncOperation.create
        : operation;

    await _box.put(
      previous.id,
      SyncItem(
        id: previous.id,
        entityType: entityType,
        entityId: entityId,
        operation: mergedOperation,
        payload: payload,
        createdAt: previous.createdAt,
      ),
    );
  }

  @override
  List<SyncItem> pending() => _byStatus(SyncStatus.pending);

  @override
  List<SyncItem> failed() => _byStatus(SyncStatus.failed);

  @override
  Future<void> markSending(Iterable<String> ids) async {
    for (final id in ids) {
      final item = _box.get(id);
      if (item == null) continue;
      await _box.put(id, item.copyWith(status: SyncStatus.sending));
    }
  }

  @override
  Future<void> markSent(Iterable<String> ids) => _box.deleteAll(ids);

  @override
  Future<void> markFailed(String id, String error) async {
    final item = _box.get(id);
    if (item == null) return;
    await _box.put(
      id,
      item.copyWith(
        status: SyncStatus.failed,
        attempts: item.attempts + 1,
        lastError: error,
      ),
    );
  }

  @override
  Future<void> retryFailed() async {
    for (final item in failed()) {
      await _box.put(item.id, item.copyWith(status: SyncStatus.pending));
    }
  }

  @override
  Future<void> recoverInterrupted() async {
    for (final item in _byStatus(SyncStatus.sending)) {
      await _box.put(item.id, item.copyWith(status: SyncStatus.pending));
    }
  }

  List<SyncItem> _byStatus(SyncStatus status) =>
      _box.values.where((item) => item.status == status).toList()
        ..sort((a, b) => a.createdAt.compareTo(b.createdAt));
}

import '../entities/sync_item.dart';

abstract interface class SyncQueueRepository {
  Future<void> enqueue({
    required SyncEntityType entityType,
    required String entityId,
    required SyncOperation operation,
    required Map<String, dynamic> payload,
  });

  List<SyncItem> pending();

  List<SyncItem> failed();

  Future<void> markSending(Iterable<String> ids);

  Future<void> markSent(Iterable<String> ids);

  Future<void> markFailed(String id, String error);

  Future<void> retryFailed();

  Future<void> recoverInterrupted();
}

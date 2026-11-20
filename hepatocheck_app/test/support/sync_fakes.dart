import 'package:hepatocheck_app/domain/entities/sync_item.dart';
import 'package:hepatocheck_app/domain/repositories/cloud_restore.dart';
import 'package:hepatocheck_app/domain/repositories/cloud_vault.dart';
import 'package:hepatocheck_app/domain/repositories/sync_queue_repository.dart';
import 'package:hepatocheck_app/domain/repositories/sync_remote.dart';

class MemorySyncQueue implements SyncQueueRepository {
  final items = <String, SyncItem>{};
  var _counter = 0;

  @override
  Future<void> enqueue({
    required SyncEntityType entityType,
    required String entityId,
    required SyncOperation operation,
    required Map<String, dynamic> payload,
  }) async {
    final id = 'item-${++_counter}';
    items[id] = SyncItem(
      id: id,
      entityType: entityType,
      entityId: entityId,
      operation: operation,
      payload: payload,
      createdAt: DateTime(2026, 11, 16, 8, 0, _counter),
    );
  }

  List<SyncItem> _byStatus(SyncStatus status) =>
      items.values.where((item) => item.status == status).toList();

  @override
  List<SyncItem> pending() => _byStatus(SyncStatus.pending);

  @override
  List<SyncItem> failed() => _byStatus(SyncStatus.failed);

  @override
  Future<void> markSending(Iterable<String> ids) async {
    for (final id in ids) {
      items[id] = items[id]!.copyWith(status: SyncStatus.sending);
    }
  }

  @override
  Future<void> markSent(Iterable<String> ids) async =>
      ids.forEach(items.remove);

  @override
  Future<void> markFailed(String id, String error) async {
    final item = items[id]!;
    items[id] = item.copyWith(
      status: SyncStatus.failed,
      attempts: item.attempts + 1,
      lastError: error,
    );
  }

  @override
  Future<void> retryFailed() async {
    for (final item in failed()) {
      items[item.id] = item.copyWith(status: SyncStatus.pending);
    }
  }

  @override
  Future<void> recoverInterrupted() async {
    for (final item in _byStatus(SyncStatus.sending)) {
      items[item.id] = item.copyWith(status: SyncStatus.pending);
    }
  }
}

class FakeSyncRemote implements SyncRemote {
  final rejected = <String>{};
  var batches = 0;

  @override
  Future<void> sendBatch(String userId, List<SyncItem> items) async {
    if (items.any((item) => rejected.contains(item.entityId))) {
      throw const SyncRemoteException('permission-denied');
    }
    batches++;
  }
}

class FakeCloudVault implements CloudVault {
  FakeCloudVault({this.unlocked = true});

  bool unlocked;
  bool keyMismatch = false;
  int resets = 0;
  final sealedPayloads = <Map<String, dynamic>>[];

  @override
  bool get isUnlocked => unlocked;

  @override
  int? get keyVersion => unlocked ? 1 : null;

  @override
  Future<void> create(String uid, String password) async => unlocked = true;

  @override
  Future<void> unlock(String uid, String password) async {
    if (keyMismatch) throw const VaultKeyMismatchException();
    unlocked = true;
  }

  @override
  Future<bool> resume(String uid) async => unlocked;

  @override
  Future<void> reset(String uid, String password) async {
    resets++;
    keyMismatch = false;
    unlocked = true;
  }

  @override
  Future<void> rewrap(String uid, String newPassword) async {
    if (!unlocked) throw const VaultLockedException();
    rewraps.add(newPassword);
  }

  final rewraps = <String>[];

  @override
  Future<void> lock() async => unlocked = false;

  @override
  Future<void> forget(String uid) async => unlocked = false;

  @override
  Future<SealedData> seal(Map<String, dynamic> data) async {
    if (!unlocked) throw const VaultLockedException();
    sealedPayloads.add(data);
    return SealedData(
      sealed: 'selado-${sealedPayloads.length}',
      nonce: 'nonce',
      keyVersion: 1,
    );
  }

  @override
  Future<Map<String, dynamic>> open(SealedData data) async {
    if (!unlocked) throw const VaultLockedException();
    final index = int.parse(data.sealed.split('-').last) - 1;
    return sealedPayloads[index];
  }
}

class FakeCloudRestore implements CloudRestore {
  FakeCloudRestore({this.report = const RestoreReport()});

  RestoreReport report;
  final restoredUids = <String>[];
  final deletedUids = <String>[];

  @override
  Future<RestoreReport> restore(String uid) async {
    restoredUids.add(uid);
    return report;
  }

  @override
  Future<void> deleteRemote(String uid, {bool includeKey = false}) async {
    if (offline) throw StateError('sem internet');
    deletedUids.add(uid);
    if (includeKey) deletedKeys.add(uid);
  }

  bool offline = false;
  final deletedKeys = <String>[];
}

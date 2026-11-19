import 'dart:math';

import '../entities/sync_item.dart';
import '../repositories/sync_queue_repository.dart';
import '../repositories/sync_remote.dart';

enum SyncSkipReason {
  alreadyRunning,
  signedOut,
  noConsent,
  noWifi,
  vaultLocked,
}

class SyncReport {
  const SyncReport({this.sent = 0, this.failed = 0, this.skipped});

  final int sent;
  final int failed;
  final SyncSkipReason? skipped;
}

typedef PayloadAnonymizer = Map<String, dynamic> Function(
  SyncEntityType entityType,
  Map<String, dynamic> payload,
);

typedef PayloadSealer = Future<Map<String, dynamic>> Function(
  Map<String, dynamic> payload,
);

class SyncPendingItems {
  SyncPendingItems({
    required this._queue,
    required this._remote,
    required this._anonymize,
    this._seal,
    this._sealReady,
    this.batchSize = 20,
  });

  static const unknownError = 'unknown';

  final SyncQueueRepository _queue;
  final SyncRemote _remote;
  final PayloadAnonymizer _anonymize;
  final PayloadSealer? _seal;
  final bool Function()? _sealReady;
  final int batchSize;
  bool _running = false;

  bool get isRunning => _running;

  Future<SyncReport> call({
    required String? userId,
    required bool hasConsent,
    required bool isOnWifi,
  }) async {
    if (_running) {
      return const SyncReport(skipped: SyncSkipReason.alreadyRunning);
    }
    if (userId == null) {
      return const SyncReport(skipped: SyncSkipReason.signedOut);
    }
    if (!hasConsent) {
      return const SyncReport(skipped: SyncSkipReason.noConsent);
    }
    if (!isOnWifi) return const SyncReport(skipped: SyncSkipReason.noWifi);
    if (_seal != null && !(_sealReady?.call() ?? true)) {
      return const SyncReport(skipped: SyncSkipReason.vaultLocked);
    }

    _running = true;
    try {
      await _queue.recoverInterrupted();
      final pending = _queue.pending();
      var sent = 0;
      var failed = 0;

      for (var start = 0; start < pending.length; start += batchSize) {
        final batch = pending.sublist(
          start,
          min(start + batchSize, pending.length),
        );
        final ids = [for (final item in batch) item.id];
        await _queue.markSending(ids);
        try {
          await _remote.sendBatch(userId, [
            for (final item in batch) await _prepare(item),
          ]);
          await _queue.markSent(ids);
          sent += batch.length;
        } catch (error) {
          final code = error is SyncRemoteException ? error.code : unknownError;
          for (final id in ids) {
            await _queue.markFailed(id, code);
          }
          failed += batch.length;
        }
      }

      return SyncReport(sent: sent, failed: failed);
    } finally {
      _running = false;
    }
  }

  Future<SyncItem> _prepare(SyncItem item) async {
    if (item.operation == SyncOperation.delete) return item;
    final seal = _seal;
    return item.copyWith(
      payload: {
        ..._anonymize(item.entityType, item.payload),
        if (seal != null) ...await seal(item.payload),
      },
    );
  }
}

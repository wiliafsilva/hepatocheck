import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/network/wifi_monitor.dart';
import '../../data/datasources/local/hive_database.dart';
import '../../data/sync/firestore_sync_remote.dart';
import '../../data/sync/hive_sync_queue_repository.dart';
import '../../domain/entities/sync_item.dart';
import '../../domain/repositories/sync_queue_repository.dart';
import '../../domain/repositories/sync_remote.dart';
import '../../domain/usecases/sync_pending_items.dart';

final syncQueueRepositoryProvider = Provider<SyncQueueRepository>(
  (ref) => HiveSyncQueueRepository(HiveDatabase.syncQueue),
);

final wifiMonitorProvider = Provider((ref) => WifiMonitor());

final isOnWifiProvider = StreamProvider<bool>(
  (ref) => ref.watch(wifiMonitorProvider).watchWifi(),
);

final syncRemoteProvider = Provider<SyncRemote>(
  (ref) => FirestoreSyncRemote(FirebaseFirestore.instance),
);

final currentUserIdProvider = Provider<String? Function()>(
  (ref) =>
      () => FirebaseAuth.instance.currentUser?.uid,
);

final syncConsentProvider = Provider<bool>((ref) => false);

final payloadAnonymizerProvider = Provider<PayloadAnonymizer>(
  (ref) =>
      (entityType, payload) => payload,
);

final syncPendingItemsProvider = Provider(
  (ref) => SyncPendingItems(
    queue: ref.watch(syncQueueRepositoryProvider),
    remote: ref.watch(syncRemoteProvider),
    anonymize: ref.watch(payloadAnonymizerProvider),
  ),
);

class SyncStatusState {
  const SyncStatusState({
    required this.pending,
    required this.failed,
    this.isSyncing = false,
    this.lastReport,
  });

  final List<SyncItem> pending;
  final List<SyncItem> failed;
  final bool isSyncing;
  final SyncReport? lastReport;
}

final syncStatusProvider =
    NotifierProvider<SyncStatusNotifier, SyncStatusState>(
      SyncStatusNotifier.new,
    );

class SyncStatusNotifier extends Notifier<SyncStatusState> {
  @override
  SyncStatusState build() => _snapshot();

  SyncStatusState _snapshot({bool isSyncing = false, SyncReport? lastReport}) {
    final queue = ref.read(syncQueueRepositoryProvider);
    return SyncStatusState(
      pending: queue.pending(),
      failed: queue.failed(),
      isSyncing: isSyncing,
      lastReport: lastReport,
    );
  }

  void refresh() => state = _snapshot(
    isSyncing: state.isSyncing,
    lastReport: state.lastReport,
  );

  Future<SyncReport> syncNow() async {
    if (state.isSyncing) {
      return const SyncReport(skipped: SyncSkipReason.alreadyRunning);
    }
    state = _snapshot(isSyncing: true, lastReport: state.lastReport);
    var report = const SyncReport(skipped: SyncSkipReason.alreadyRunning);
    try {
      final isOnWifi = await ref.read(wifiMonitorProvider).isOnWifi();
      report = await ref.read(syncPendingItemsProvider)(
        userId: ref.read(currentUserIdProvider)(),
        hasConsent: ref.read(syncConsentProvider),
        isOnWifi: isOnWifi,
      );
      return report;
    } finally {
      if (ref.mounted) state = _snapshot(lastReport: report);
    }
  }

  Future<SyncReport> retryFailed() async {
    await ref.read(syncQueueRepositoryProvider).retryFailed();
    refresh();
    return syncNow();
  }
}

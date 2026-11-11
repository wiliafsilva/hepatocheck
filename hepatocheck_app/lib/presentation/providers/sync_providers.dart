import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/network/wifi_monitor.dart';
import '../../data/datasources/local/hive_database.dart';
import '../../data/sync/hive_sync_queue_repository.dart';
import '../../domain/repositories/sync_queue_repository.dart';

final syncQueueRepositoryProvider = Provider<SyncQueueRepository>(
  (ref) => HiveSyncQueueRepository(HiveDatabase.syncQueue),
);

final wifiMonitorProvider = Provider((ref) => WifiMonitor());

final isOnWifiProvider = StreamProvider<bool>(
  (ref) => ref.watch(wifiMonitorProvider).watchWifi(),
);

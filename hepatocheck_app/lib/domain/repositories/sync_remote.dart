import '../entities/sync_item.dart';

class SyncRemoteException implements Exception {
  const SyncRemoteException(this.code);

  final String code;

  @override
  String toString() => 'SyncRemoteException($code)';
}

abstract interface class SyncRemote {
  Future<void> sendBatch(String userId, List<SyncItem> items);
}

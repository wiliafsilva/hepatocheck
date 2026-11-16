import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/datasources/local/hive_database.dart';
import '../../data/repositories/hive_sync_consent_repository.dart';
import '../../domain/repositories/sync_consent_repository.dart';

final syncConsentRepositoryProvider = Provider<SyncConsentRepository>(
  (ref) => HiveSyncConsentRepository(HiveDatabase.syncConsent),
);

/// Estado do consentimento (verdadeiro quando autorizado).
final syncConsentControllerProvider =
    NotifierProvider<SyncConsentController, bool>(SyncConsentController.new);

class SyncConsentController extends Notifier<bool> {
  @override
  bool build() => ref.read(syncConsentRepositoryProvider).isGranted;

  Future<void> grant() async {
    await ref.read(syncConsentRepositoryProvider).grant(DateTime.now());
    state = true;
  }

  Future<void> revoke() async {
    await ref.read(syncConsentRepositoryProvider).revoke();
    state = false;
  }
}

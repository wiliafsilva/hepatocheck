import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart';

import '../../data/datasources/local/hive_database.dart';
import '../../data/datasources/local/hive_local_data_eraser.dart';
import '../../domain/repositories/local_data_eraser.dart';
import 'account_session.dart';
import 'auth_providers.dart';
import 'drink_providers.dart';
import 'exam_providers.dart';
import 'goal_providers.dart';
import 'consent_providers.dart';
import 'sync_providers.dart';

final localDataEraserProvider = Provider<LocalDataEraser>(
  (ref) => HiveLocalDataEraser([
    HiveDatabase.drinks,
    HiveDatabase.exams,
    HiveDatabase.syncQueue,
    HiveDatabase.auditLog,
    HiveDatabase.goals,
    HiveDatabase.followUp,
    HiveDatabase.syncConsent,
  ], afterErase: HiveDatabase.markTrackingStarted),
);

const cloudDeleteTimeout = Duration(seconds: 20);

Future<bool> eraseAllData(WidgetRef ref) async {
  final uid = ref.read(authRepositoryProvider).currentUser?.uid;
  if (uid != null) {
    try {
      await ref
          .read(cloudRestoreProvider)
          .deleteRemote(uid)
          .timeout(cloudDeleteTimeout);
    } catch (_) {
      return false;
    }
  }
  await eraseAllLocalData(ref);
  return true;
}

Future<void> eraseAllLocalData(WidgetRef ref) async {
  await ref.read(localDataEraserProvider).eraseAll();
  final uid = ref.read(authRepositoryProvider).currentUser?.uid;
  if (uid != null) await ref.read(cloudVaultProvider).forget(uid);
  refreshAfterErase(ref.invalidate);
}

void refreshAfterErase(void Function(ProviderOrFamily provider) invalidate) {
  for (final provider in <ProviderOrFamily>[
    drinksProvider,
    examsProvider,
    goalsProvider,
    followUpSettingsProvider,
    syncConsentControllerProvider,
    syncStatusProvider,
  ]) {
    invalidate(provider);
  }
}

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/datasources/local/hive_database.dart';
import '../../data/datasources/local/hive_local_data_eraser.dart';
import '../../domain/repositories/local_data_eraser.dart';
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

Future<void> eraseAllLocalData(WidgetRef ref) async {
  await ref.read(localDataEraserProvider).eraseAll();
  final uid = ref.read(authRepositoryProvider).currentUser?.uid;
  if (uid != null) await ref.read(cloudVaultProvider).forget(uid);
  ref
    ..invalidate(drinksProvider)
    ..invalidate(examsProvider)
    ..invalidate(goalsProvider)
    ..invalidate(followUpSettingsProvider)
    ..invalidate(syncConsentControllerProvider)
    ..invalidate(syncStatusProvider);
}

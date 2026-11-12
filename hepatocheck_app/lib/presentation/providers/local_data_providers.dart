import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/datasources/local/hive_database.dart';
import '../../data/datasources/local/hive_local_data_eraser.dart';
import '../../domain/repositories/local_data_eraser.dart';
import 'drink_providers.dart';
import 'exam_providers.dart';
import 'sync_providers.dart';

final localDataEraserProvider = Provider<LocalDataEraser>(
  (ref) => HiveLocalDataEraser([
    HiveDatabase.drinks,
    HiveDatabase.exams,
    HiveDatabase.syncQueue,
    HiveDatabase.auditLog,
  ]),
);

Future<void> eraseAllLocalData(WidgetRef ref) async {
  await ref.read(localDataEraserProvider).eraseAll();
  ref
    ..invalidate(drinksProvider)
    ..invalidate(examsProvider)
    ..invalidate(syncStatusProvider);
}

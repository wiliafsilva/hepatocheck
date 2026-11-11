import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/datasources/local/hive_database.dart';
import '../../data/repositories/hive_audit_log_repository.dart';
import '../../data/repositories/hive_drink_repository.dart';
import '../../domain/entities/drink_entry.dart';
import '../../domain/repositories/audit_log_repository.dart';
import '../../domain/repositories/drink_repository.dart';
import '../../domain/usecases/convert_to_standard_drinks.dart';
import '../../domain/usecases/validate_drink_input.dart';

final auditLogRepositoryProvider = Provider<AuditLogRepository>(
  (ref) => HiveAuditLogRepository(HiveDatabase.auditLog),
);

final drinkRepositoryProvider = Provider<DrinkRepository>(
  (ref) => HiveDrinkRepository(
    HiveDatabase.drinks,
    ref.watch(auditLogRepositoryProvider),
  ),
);

final convertToStandardDrinksProvider = Provider(
  (ref) => const ConvertToStandardDrinks(),
);

final validateDrinkInputProvider = Provider((ref) => const ValidateDrinkInput());

final drinksProvider = NotifierProvider<DrinksNotifier, List<DrinkEntry>>(
  DrinksNotifier.new,
);

class DrinksNotifier extends Notifier<List<DrinkEntry>> {
  @override
  List<DrinkEntry> build() => ref.read(drinkRepositoryProvider).getAll();

  Future<void> save(DrinkEntry entry) async {
    final repository = ref.read(drinkRepositoryProvider);
    await repository.save(entry);
    state = repository.getAll();
  }

  Future<void> delete(String id) async {
    final repository = ref.read(drinkRepositoryProvider);
    await repository.delete(id);
    state = repository.getAll();
  }
}

import '../entities/drink_entry.dart';

abstract interface class DrinkRepository {
  List<DrinkEntry> getAll();

  DrinkEntry? getById(String id);

  Future<void> save(DrinkEntry entry);

  Future<void> delete(String id);
}

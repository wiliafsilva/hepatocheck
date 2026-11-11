import '../entities/drink_entry.dart';

/// Contrato do repositório do diário de álcool.
abstract class DrinkRepository {
  /// Emite a lista atual e uma nova lista a cada alteração.
  Stream<List<DrinkEntry>> watchAll();

  /// Cria o registro ou substitui o que tem o mesmo id.
  Future<void> save(DrinkEntry entry);

  Future<void> delete(String id);
}

import 'dart:async';

import '../../domain/entities/drink_entry.dart';
import '../../domain/repositories/drink_repository.dart';

/// Repositório em memória do diário, usado até o Hive com AES ser ligado.
class InMemoryDrinkRepository implements DrinkRepository {
  final _items = <String, DrinkEntry>{};
  final _changes = StreamController<void>.broadcast();

  List<DrinkEntry> _snapshot() => List.unmodifiable(_items.values);

  @override
  Stream<List<DrinkEntry>> watchAll() {
    late final StreamController<List<DrinkEntry>> controller;
    StreamSubscription<void>? sub;
    controller = StreamController<List<DrinkEntry>>(
      onListen: () {
        controller.add(_snapshot());
        sub = _changes.stream.listen((_) => controller.add(_snapshot()));
      },
      onCancel: () => sub?.cancel(),
    );
    return controller.stream;
  }

  @override
  Future<void> save(DrinkEntry entry) async {
    _items[entry.id] = entry;
    _changes.add(null);
  }

  @override
  Future<void> delete(String id) async {
    _items.remove(id);
    _changes.add(null);
  }
}

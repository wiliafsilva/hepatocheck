import 'package:hepatocheck_app/domain/entities/drink_entry.dart';
import 'package:hepatocheck_app/domain/entities/drink_type.dart';
import 'package:hepatocheck_app/domain/entities/lab_exam.dart';
import 'package:hepatocheck_app/domain/repositories/drink_repository.dart';
import 'package:hepatocheck_app/domain/repositories/exam_repository.dart';
import 'package:hepatocheck_app/domain/usecases/convert_to_standard_drinks.dart';

/// Exame de teste. Padrão: FIB-4 = (45 x 30) / (250 x raiz(36)) = 0,90.
LabExam testExam({
  String id = 'e1',
  DateTime? examDate,
  int age = 45,
  double ast = 30,
  double alt = 36,
  double platelets = 250,
}) {
  final date = examDate ?? DateTime(2026, 11, 1);
  return LabExam(
    id: id,
    examDate: date,
    age: age,
    ast: ast,
    alt: alt,
    platelets: platelets,
    createdAt: date,
    updatedAt: date,
  );
}

/// Registro que vale exatamente [standardDrinks] drinques padrão
/// (14 g de álcool puro cada).
DrinkEntry testDrink(double standardDrinks, DateTime consumedAt, {String? id}) {
  return DrinkEntry(
    id: id ?? 'd-${consumedAt.microsecondsSinceEpoch}-$standardDrinks',
    type: DrinkType.spirit,
    volumeMl:
        ConvertToStandardDrinks.gramsPerStandardDrink /
        ConvertToStandardDrinks.ethanolDensity *
        standardDrinks,
    alcoholPercent: 100,
    quantity: 1,
    consumedAt: consumedAt,
    createdAt: consumedAt,
    updatedAt: consumedAt,
  );
}

class MemoryExamRepository implements ExamRepository {
  final _items = <String, LabExam>{};

  @override
  List<LabExam> getAll() => _items.values.toList();

  @override
  LabExam? getById(String id) => _items[id];

  @override
  Future<void> save(LabExam exam) async => _items[exam.id] = exam;

  @override
  Future<void> delete(String id) async => _items.remove(id);
}

class MemoryDrinkRepository implements DrinkRepository {
  final _items = <String, DrinkEntry>{};

  @override
  List<DrinkEntry> getAll() => _items.values.toList();

  @override
  DrinkEntry? getById(String id) => _items[id];

  @override
  Future<void> save(DrinkEntry entry) async => _items[entry.id] = entry;

  @override
  Future<void> delete(String id) async => _items.remove(id);
}

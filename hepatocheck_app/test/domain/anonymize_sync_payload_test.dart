import 'package:flutter_test/flutter_test.dart';
import 'package:hepatocheck_app/data/models/firestore_mappers.dart';
import 'package:hepatocheck_app/domain/entities/sync_item.dart';
import 'package:hepatocheck_app/domain/usecases/anonymize_sync_payload.dart';

import '../support/test_data.dart';

void main() {
  const anonymize = AnonymizeSyncPayload();

  bool hasExactTime(Object? value) {
    if (value is! DateTime) return false;
    return value.hour != 0 ||
        value.minute != 0 ||
        value.second != 0 ||
        value.millisecond != 0;
  }

  test('exame: idade vira faixa etária e a hora é removida', () {
    final exam = testExam(
      age: 43,
      examDate: DateTime(2026, 11, 5, 14, 37, 12),
    );
    final result = anonymize(
      SyncEntityType.exam,
      FirestoreMappers.examToFirestore(exam),
    );

    expect(result['ageRange'], '40-49');
    expect(result.containsKey('age'), isFalse);
    expect(result.values.any(hasExactTime), isFalse);
    expect(result['ast'], 30);
  });

  test('drinque: só a data do consumo, sem hora', () {
    final drink = testDrink(2, DateTime(2026, 11, 14, 22, 45, 30));
    final result = anonymize(
      SyncEntityType.drink,
      FirestoreMappers.drinkToFirestore(drink),
    );

    expect(result['consumedAt'], DateTime.utc(2026, 11, 14));
    expect(result.values.any(hasExactTime), isFalse);
  });

  test('campos desconhecidos como nome, e-mail e notas não passam', () {
    final result = anonymize(SyncEntityType.drink, {
      'type': 'beer',
      'quantity': 1,
      'name': 'Victor',
      'email': 'victor@exemplo.com',
      'notes': 'depois do jogo',
      'uid': 'abc',
    });

    expect(result.keys.toSet(), {'type', 'quantity'});
  });

  test('meta mantém datas sem hora e fim nulo', () {
    final result = anonymize(SyncEntityType.goal, {
      'type': 'maxDrinksPerWeek',
      'target': 7,
      'startDate': DateTime(2026, 11, 1, 8, 30),
      'endDate': null,
      'active': true,
      'createdAt': DateTime(2026, 11, 1, 8, 30),
      'updatedAt': DateTime(2026, 11, 2, 9, 15),
    });

    expect(result['endDate'], isNull);
    expect(result['startDate'], DateTime.utc(2026, 11, 1));
    expect(result.values.any(hasExactTime), isFalse);
  });

  test('faixa etária cobre as bordas', () {
    expect(AnonymizeSyncPayload.ageRange(18), '10-19');
    expect(AnonymizeSyncPayload.ageRange(40), '40-49');
    expect(AnonymizeSyncPayload.ageRange(49), '40-49');
    expect(AnonymizeSyncPayload.ageRange(120), '120-129');
    expect(AnonymizeSyncPayload.ageRange(null), isNull);
    expect(AnonymizeSyncPayload.ageRange(-1), isNull);
  });

  test('o documento anonimizado não tem nome nem e-mail em nenhum valor', () {
    final exam = testExam(age: 52);
    final result = anonymize(
      SyncEntityType.exam,
      FirestoreMappers.examToFirestore(exam),
    );
    final text = result.toString().toLowerCase();

    expect(text.contains('@'), isFalse);
    expect(text.contains('nome'), isFalse);
    expect(text.contains('email'), isFalse);
  });
}

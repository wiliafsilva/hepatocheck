import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hepatocheck_app/data/models/firestore_mappers.dart';
import 'package:hepatocheck_app/domain/entities/drink_entry.dart';
import 'package:hepatocheck_app/domain/entities/drink_type.dart';
import 'package:hepatocheck_app/domain/entities/lab_exam.dart';
import 'package:hepatocheck_app/domain/entities/reduction_goal.dart';

void main() {
  late FakeFirebaseFirestore firestore;

  setUp(() => firestore = FakeFirebaseFirestore());

  Future<Map<String, dynamic>> roundTrip(
    String collection,
    String id,
    Map<String, dynamic> data,
  ) async {
    final doc = firestore
        .collection('users')
        .doc('u1')
        .collection(collection)
        .doc(id);
    await doc.set(data);
    return (await doc.get()).data()!;
  }

  final created = DateTime.utc(2026, 11, 14, 22, 31);

  test('drinque vai e volta do Firestore sem perder dados', () async {
    final entry = DrinkEntry(
      id: 'd1',
      type: DrinkType.wine,
      volumeMl: 150,
      alcoholPercent: 12.5,
      quantity: 2,
      consumedAt: DateTime.utc(2026, 11, 14, 22, 30),
      createdAt: created,
      updatedAt: created,
    );

    final data = await roundTrip(
      'drinks',
      'd1',
      FirestoreMappers.drinkToFirestore(entry),
    );
    final back = FirestoreMappers.drinkFromFirestore('d1', data);

    expect(
      data.keys,
      unorderedEquals([
        'type',
        'volumeMl',
        'alcoholPercent',
        'quantity',
        'consumedAt',
        'createdAt',
        'updatedAt',
      ]),
    );
    expect(data['type'], 'wine');
    expect(back.id, 'd1');
    expect(back.type, DrinkType.wine);
    expect(back.volumeMl, 150);
    expect(back.alcoholPercent, 12.5);
    expect(back.quantity, 2);
    expect(back.consumedAt.isAtSameMomentAs(entry.consumedAt), isTrue);
    expect(back.updatedAt.isAtSameMomentAs(created), isTrue);
  });

  test('exame vai e volta do Firestore sem perder dados', () async {
    final exam = LabExam(
      id: 'e1',
      examDate: DateTime.utc(2026, 11, 10),
      age: 45,
      ast: 38,
      alt: 40,
      platelets: 220,
      createdAt: created,
      updatedAt: created,
    );

    final data = await roundTrip(
      'exams',
      'e1',
      FirestoreMappers.examToFirestore(exam),
    );
    final back = FirestoreMappers.examFromFirestore('e1', data);

    expect(data.containsKey('id'), isFalse);
    expect(back.age, 45);
    expect(back.ast, 38);
    expect(back.alt, 40);
    expect(back.platelets, 220);
    expect(back.examDate.isAtSameMomentAs(exam.examDate), isTrue);
  });

  test('meta vai e volta do Firestore, com e sem data final', () async {
    final goal = ReductionGoal(
      id: 'g1',
      type: GoalType.alcoholFreeDaysPerWeek,
      target: 3,
      startDate: DateTime.utc(2026, 11, 16),
      active: true,
      createdAt: created,
      updatedAt: created,
    );

    final open = FirestoreMappers.goalFromFirestore(
      'g1',
      await roundTrip('goals', 'g1', FirestoreMappers.goalToFirestore(goal)),
    );
    final closed = FirestoreMappers.goalFromFirestore(
      'g2',
      await roundTrip(
        'goals',
        'g2',
        FirestoreMappers.goalToFirestore(
          goal.copyWith(endDate: DateTime.utc(2026, 12, 16), active: false),
        ),
      ),
    );

    expect(open.type, GoalType.alcoholFreeDaysPerWeek);
    expect(open.target, 3);
    expect(open.endDate, isNull);
    expect(open.active, isTrue);
    expect(
      closed.endDate!.isAtSameMomentAs(DateTime.utc(2026, 12, 16)),
      isTrue,
    );
    expect(closed.active, isFalse);
  });

  test('datas locais são enviadas em UTC', () {
    final local = DateTime(2026, 11, 14, 22, 30);
    final data = FirestoreMappers.drinkToFirestore(
      DrinkEntry(
        id: 'd1',
        type: DrinkType.beer,
        volumeMl: 350,
        alcoholPercent: 5,
        quantity: 1,
        consumedAt: local,
        createdAt: local,
        updatedAt: local,
      ),
    );

    final sent = data['consumedAt'] as DateTime;
    expect(sent.isUtc, isTrue);
    expect(sent.isAtSameMomentAs(local), isTrue);
  });

  test('aceita números inteiros e datas em texto vindos da nuvem', () {
    final back = FirestoreMappers.examFromFirestore('e1', {
      'examDate': '2026-11-10T00:00:00Z',
      'age': 45.0,
      'ast': 38,
      'alt': 40,
      'platelets': 220,
      'createdAt': '2026-11-10T00:00:00Z',
      'updatedAt': '2026-11-10T00:00:00Z',
    });

    expect(back.age, 45);
    expect(back.ast, 38.0);
    expect(back.examDate, DateTime.utc(2026, 11, 10));
  });

  test('data inválida gera erro de formato', () {
    expect(
      () => FirestoreMappers.examFromFirestore('e1', {
        'examDate': 123,
        'age': 45,
        'ast': 38,
        'alt': 40,
        'platelets': 220,
        'createdAt': 123,
        'updatedAt': 123,
      }),
      throwsFormatException,
    );
  });
}

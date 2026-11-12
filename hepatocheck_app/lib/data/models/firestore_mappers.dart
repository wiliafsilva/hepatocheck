import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/entities/drink_entry.dart';
import '../../domain/entities/drink_type.dart';
import '../../domain/entities/lab_exam.dart';
import '../../domain/entities/reduction_goal.dart';

abstract final class FirestoreMappers {
  static Map<String, dynamic> drinkToFirestore(DrinkEntry entry) => {
    'type': entry.type.name,
    'volumeMl': entry.volumeMl,
    'alcoholPercent': entry.alcoholPercent,
    'quantity': entry.quantity,
    'consumedAt': entry.consumedAt.toUtc(),
    'createdAt': entry.createdAt.toUtc(),
    'updatedAt': entry.updatedAt.toUtc(),
  };

  static DrinkEntry drinkFromFirestore(String id, Map<String, dynamic> data) =>
      DrinkEntry(
        id: id,
        type: DrinkType.values.byName(data['type'] as String),
        volumeMl: _double(data['volumeMl']),
        alcoholPercent: _double(data['alcoholPercent']),
        quantity: (data['quantity'] as num).toInt(),
        consumedAt: _date(data['consumedAt']),
        createdAt: _date(data['createdAt']),
        updatedAt: _date(data['updatedAt']),
      );

  static Map<String, dynamic> examToFirestore(LabExam exam) => {
    'examDate': exam.examDate.toUtc(),
    'age': exam.age,
    'ast': exam.ast,
    'alt': exam.alt,
    'platelets': exam.platelets,
    'createdAt': exam.createdAt.toUtc(),
    'updatedAt': exam.updatedAt.toUtc(),
  };

  static LabExam examFromFirestore(String id, Map<String, dynamic> data) =>
      LabExam(
        id: id,
        examDate: _date(data['examDate']),
        age: (data['age'] as num).toInt(),
        ast: _double(data['ast']),
        alt: _double(data['alt']),
        platelets: _double(data['platelets']),
        createdAt: _date(data['createdAt']),
        updatedAt: _date(data['updatedAt']),
      );

  static Map<String, dynamic> goalToFirestore(ReductionGoal goal) => {
    'type': goal.type.name,
    'target': goal.target,
    'startDate': goal.startDate.toUtc(),
    'endDate': goal.endDate?.toUtc(),
    'active': goal.active,
    'createdAt': goal.createdAt.toUtc(),
    'updatedAt': goal.updatedAt.toUtc(),
  };

  static ReductionGoal goalFromFirestore(
    String id,
    Map<String, dynamic> data,
  ) => ReductionGoal(
    id: id,
    type: GoalType.values.byName(data['type'] as String),
    target: (data['target'] as num).toInt(),
    startDate: _date(data['startDate']),
    endDate: data['endDate'] == null ? null : _date(data['endDate']),
    active: data['active'] as bool,
    createdAt: _date(data['createdAt']),
    updatedAt: _date(data['updatedAt']),
  );

  static double _double(Object? value) => (value as num).toDouble();

  static DateTime _date(Object? value) => switch (value) {
    Timestamp() => value.toDate(),
    DateTime() => value,
    String() => DateTime.parse(value),
    _ => throw FormatException('Data inválida: $value'),
  };
}

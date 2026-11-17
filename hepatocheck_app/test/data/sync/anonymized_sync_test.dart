import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hepatocheck_app/data/models/hive_registrar.g.dart';
import 'package:hepatocheck_app/data/repositories/hive_audit_log_repository.dart';
import 'package:hepatocheck_app/data/repositories/hive_drink_repository.dart';
import 'package:hepatocheck_app/data/repositories/hive_exam_repository.dart';
import 'package:hepatocheck_app/data/repositories/hive_goal_repository.dart';
import 'package:hepatocheck_app/data/sync/firestore_sync_remote.dart';
import 'package:hepatocheck_app/data/sync/hive_sync_queue_repository.dart';
import 'package:hepatocheck_app/domain/entities/audit_entry.dart';
import 'package:hepatocheck_app/domain/entities/drink_entry.dart';
import 'package:hepatocheck_app/domain/entities/drink_type.dart';
import 'package:hepatocheck_app/domain/entities/lab_exam.dart';
import 'package:hepatocheck_app/domain/entities/reduction_goal.dart';
import 'package:hepatocheck_app/domain/entities/sync_item.dart';
import 'package:hepatocheck_app/domain/usecases/anonymize_sync_payload.dart';
import 'package:hepatocheck_app/domain/usecases/sync_pending_items.dart';
import 'package:hive_ce/hive_ce.dart';

void main() {
  const uid = 'uid-Xy12Ab34';
  const email = 'maria.silva@exemplo.com';
  const name = 'Maria Silva';

  late Directory dir;
  late FakeFirebaseFirestore firestore;
  late HiveSyncQueueRepository queue;
  late HiveDrinkRepository drinks;
  late HiveExamRepository exams;
  late HiveGoalRepository goals;
  late SyncPendingItems sync;

  setUpAll(() => Hive.registerAdapters());

  setUp(() async {
    dir = await Directory.systemTemp.createTemp('anonymized_sync_test');
    Hive.init(dir.path);
    final cipher = HiveAesCipher(
      List<int>.generate(32, (_) => Random.secure().nextInt(256)),
    );
    var counter = 0;
    var clock = DateTime(2026, 11, 16, 21, 47, 13);
    DateTime now() => clock = clock.add(const Duration(seconds: 1));

    queue = HiveSyncQueueRepository(
      await Hive.openBox<SyncItem>('sync_queue', encryptionCipher: cipher),
      now: now,
      newId: () => 'fila-${++counter}',
    );
    drinks = HiveDrinkRepository(
      await Hive.openBox<DrinkEntry>('drinks', encryptionCipher: cipher),
      HiveAuditLogRepository(
        await Hive.openBox<AuditEntry>('audit_log', encryptionCipher: cipher),
        now: now,
        newId: () => 'log-${++counter}',
      ),
      queue,
    );
    exams = HiveExamRepository(
      await Hive.openBox<LabExam>('exams', encryptionCipher: cipher),
      queue,
    );
    goals = HiveGoalRepository(
      await Hive.openBox<String>('reduction_goals', encryptionCipher: cipher),
      queue,
    );
    firestore = FakeFirebaseFirestore();
    sync = SyncPendingItems(
      queue: queue,
      remote: FirestoreSyncRemote(firestore),
      anonymize: const AnonymizeSyncPayload().call,
    );
  });

  tearDown(() async {
    await Hive.close();
    await dir.delete(recursive: true);
  });

  final consumedAt = DateTime(2026, 11, 14, 23, 41, 27);
  final examDate = DateTime(2026, 11, 10, 7, 32, 5);
  final createdAt = DateTime(2026, 11, 15, 18, 22, 49);

  DrinkEntry drink() => DrinkEntry(
    id: '3f6c2a0e-7b1d-4c5e-9a8f-1e2d3c4b5a69',
    type: DrinkType.beer,
    volumeMl: 350,
    alcoholPercent: 5,
    quantity: 2,
    consumedAt: consumedAt,
    createdAt: createdAt,
    updatedAt: createdAt,
  );

  LabExam exam() => LabExam(
    id: '9b8a7c6d-5e4f-4a3b-8c2d-1e0f9a8b7c6d',
    examDate: examDate,
    age: 47,
    ast: 38,
    alt: 41,
    platelets: 215,
    createdAt: createdAt,
    updatedAt: createdAt,
  );

  ReductionGoal goal() => ReductionGoal(
    id: '1a2b3c4d-5e6f-4a7b-8c9d-0e1f2a3b4c5d',
    type: GoalType.maxDrinksPerWeek,
    target: 7,
    startDate: DateTime(2026, 11, 9, 10, 15),
    active: true,
    createdAt: createdAt,
    updatedAt: createdAt,
  );

  Future<Map<String, dynamic>> sentDocument(
    String collection,
    String id,
  ) async {
    final snapshot = await firestore
        .collection('users')
        .doc(uid)
        .collection(collection)
        .doc(id)
        .get();
    expect(snapshot.exists, isTrue, reason: '$collection/$id não foi enviado');
    return snapshot.data()!;
  }

  Future<Map<String, Map<String, dynamic>>> sendAll() async {
    await drinks.save(drink());
    await exams.save(exam());
    await goals.save(goal());

    final queued = queue.pending().length;
    final report = await sync(userId: uid, hasConsent: true, isOnWifi: true);
    expect(report.sent, queued);
    expect(report.failed, 0);
    expect(queue.pending(), isEmpty);

    return {
      'drinks': await sentDocument('drinks', drink().id),
      'exams': await sentDocument('exams', exam().id),
      'goals': await sentDocument('goals', goal().id),
    };
  }

  Iterable<DateTime> datesIn(Map<String, dynamic> document) => document.values
      .whereType<Timestamp>()
      .map((value) => value.toDate().toUtc());

  group('teste 5: o documento enviado ao Firestore está anonimizado', () {
    test('cada documento leva só os campos aceitos pelas regras', () async {
      final sent = await sendAll();

      expect(sent['drinks']!.keys.toSet(), {
        'type',
        'volumeMl',
        'alcoholPercent',
        'quantity',
        'consumedAt',
        'createdAt',
        'updatedAt',
      });
      expect(sent['exams']!.keys.toSet(), {
        'examDate',
        'ageRange',
        'ast',
        'alt',
        'platelets',
        'createdAt',
        'updatedAt',
      });
      expect(sent['goals']!.keys.toSet(), {
        'type',
        'target',
        'startDate',
        'endDate',
        'active',
        'createdAt',
        'updatedAt',
      });
    });

    test('a idade exata vira faixa etária', () async {
      final sent = await sendAll();

      expect(sent['exams']!.containsKey('age'), isFalse);
      expect(sent['exams']!['ageRange'], '40-49');
      expect(sent['exams']!.values, isNot(contains(47)));
    });

    test('nenhuma data leva o horário exato', () async {
      final sent = await sendAll();

      for (final document in sent.values) {
        final dates = datesIn(document).toList();
        expect(dates, isNotEmpty);
        for (final date in dates) {
          expect(
            [date.hour, date.minute, date.second, date.millisecond],
            [0, 0, 0, 0],
          );
        }
      }
      expect(
        sent['drinks']!['consumedAt'],
        Timestamp.fromDate(DateTime.utc(2026, 11, 14)),
      );
      expect(
        sent['exams']!['examDate'],
        Timestamp.fromDate(DateTime.utc(2026, 11, 10)),
      );
    });

    test('nome, e-mail, observações e uid não chegam à nuvem', () async {
      await queue.enqueue(
        entityType: SyncEntityType.exam,
        entityId: 'exame-com-extras',
        operation: SyncOperation.create,
        payload: {
          'examDate': examDate,
          'age': 33,
          'ast': 25,
          'alt': 30,
          'platelets': 260,
          'createdAt': createdAt,
          'updatedAt': createdAt,
          'name': name,
          'email': email,
          'notes': 'exame pedido pelo Dr. Souza',
          'uid': uid,
        },
      );
      final sent = await sendAll();
      sent['extra'] = await sentDocument('exams', 'exame-com-extras');

      for (final document in sent.values) {
        final text = document.toString();
        expect(text, isNot(contains(name)));
        expect(text, isNot(contains(email)));
        expect(text, isNot(contains('@')));
        expect(text, isNot(contains('Souza')));
        expect(text, isNot(contains(uid)));
      }
      expect(sent['extra']!['ageRange'], '30-39');
    });

    test(
      'só vão para a nuvem as três coleções, sem o registro de alterações',
      () async {
        await sendAll();

        final user = await firestore.collection('users').doc(uid).get();
        expect(user.exists, isFalse);
        final dump = jsonDecode(firestore.dump()) as Map<String, dynamic>;
        expect(dump.keys, ['users']);
        final folders = (dump['users'] as Map<String, dynamic>)[uid] as Map;
        expect(folders.keys.toSet(), {'drinks', 'exams', 'goals'});
        expect(firestore.dump(), isNot(contains('hash')));
      },
    );

    test('a exclusão remove o documento sem enviar conteúdo', () async {
      await sendAll();
      await exams.delete(exam().id);

      final report = await sync(userId: uid, hasConsent: true, isOnWifi: true);

      expect(report.sent, 1);
      final snapshot = await firestore
          .collection('users')
          .doc(uid)
          .collection('exams')
          .doc(exam().id)
          .get();
      expect(snapshot.exists, isFalse);
    });
  });
}

import 'dart:io';
import 'dart:math';

import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hepatocheck_app/data/models/hive_registrar.g.dart';
import 'package:hepatocheck_app/data/repositories/hive_audit_log_repository.dart';
import 'package:hepatocheck_app/data/repositories/hive_drink_repository.dart';
import 'package:hepatocheck_app/data/repositories/hive_exam_repository.dart';
import 'package:hepatocheck_app/data/repositories/hive_goal_repository.dart';
import 'package:hepatocheck_app/data/sync/firestore_cloud_restore.dart';
import 'package:hepatocheck_app/data/sync/firestore_cloud_vault.dart';
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

class _Device {
  _Device._(
    this.name,
    this.queue,
    this.auditBox,
    this.drinks,
    this.exams,
    this.goals,
    this.vault,
    this.sync,
    this.restore,
  );

  final String name;
  final HiveSyncQueueRepository queue;
  final Box<AuditEntry> auditBox;
  final HiveDrinkRepository drinks;
  final HiveExamRepository exams;
  final HiveGoalRepository goals;
  final FirestoreCloudVault vault;
  final SyncPendingItems sync;
  final FirestoreCloudRestore restore;

  static Future<_Device> open(
    String name,
    FakeFirebaseFirestore firestore,
  ) async {
    FlutterSecureStorage.setMockInitialValues({});
    final cipher = HiveAesCipher(
      List<int>.generate(32, (_) => Random.secure().nextInt(256)),
    );
    var counter = 0;
    final queue = HiveSyncQueueRepository(
      await Hive.openBox<SyncItem>('fila_$name', encryptionCipher: cipher),
      newId: () => '$name-fila-${++counter}',
    );
    final auditBox = await Hive.openBox<AuditEntry>(
      'log_$name',
      encryptionCipher: cipher,
    );
    final drinks = HiveDrinkRepository(
      await Hive.openBox<DrinkEntry>('drinks_$name', encryptionCipher: cipher),
      HiveAuditLogRepository(auditBox, newId: () => '$name-log-${++counter}'),
      queue,
    );
    final exams = HiveExamRepository(
      await Hive.openBox<LabExam>('exams_$name', encryptionCipher: cipher),
      queue,
    );
    final goals = HiveGoalRepository(
      await Hive.openBox<String>('goals_$name', encryptionCipher: cipher),
      queue,
    );
    final vault = FirestoreCloudVault(firestore, iterations: 1000);
    return _Device._(
      name,
      queue,
      auditBox,
      drinks,
      exams,
      goals,
      vault,
      SyncPendingItems(
        queue: queue,
        remote: FirestoreSyncRemote(firestore),
        anonymize: const AnonymizeSyncPayload().call,
        seal: (payload) async => (await vault.seal(payload)).toFields(),
        sealReady: () => vault.isUnlocked,
      ),
      FirestoreCloudRestore(
        firestore,
        vault,
        drinks: drinks,
        exams: exams,
        goals: goals,
        queue: queue,
      ),
    );
  }

  Future<SyncReport> send() =>
      sync(userId: _uid, hasConsent: true, isOnWifi: true);
}

const _uid = 'uid-1';
const _password = 'senha-forte-1';

void main() {
  late Directory dir;
  late FakeFirebaseFirestore firestore;

  setUpAll(() => Hive.registerAdapters());

  setUp(() async {
    dir = await Directory.systemTemp.createTemp('cloud_restore_test');
    Hive.init(dir.path);
    firestore = FakeFirebaseFirestore();
  });

  tearDown(() async {
    await Hive.close();
    await dir.delete(recursive: true);
  });

  final created = DateTime(2026, 11, 15, 18, 22, 49);

  DrinkEntry drink({String id = 'drinque-1', int quantity = 2}) => DrinkEntry(
    id: id,
    type: DrinkType.beer,
    volumeMl: 350,
    alcoholPercent: 5,
    quantity: quantity,
    consumedAt: DateTime(2026, 11, 14, 23, 41, 27),
    createdAt: created,
    updatedAt: created,
  );

  LabExam exam({DateTime? updatedAt, double ast = 38}) => LabExam(
    id: 'exame-1',
    examDate: DateTime(2026, 11, 10, 7, 32, 5),
    age: 47,
    ast: ast,
    alt: 41,
    platelets: 215,
    createdAt: created,
    updatedAt: updatedAt ?? created,
  );

  final goal = ReductionGoal(
    id: 'meta-1',
    type: GoalType.maxDrinksPerWeek,
    target: 7,
    startDate: DateTime(2026, 11, 9),
    active: true,
    createdAt: created,
    updatedAt: created,
  );

  Future<_Device> deviceWithBackup() async {
    final a = await _Device.open('a', firestore);
    await a.vault.create(_uid, _password);
    await a.drinks.save(drink());
    await a.exams.save(exam());
    await a.goals.save(goal);
    expect((await a.send()).sent, 3);
    return a;
  }

  test(
    'outro aparelho recebe tudo com os valores exatos ao entrar na conta',
    () async {
      await deviceWithBackup();

      final b = await _Device.open('b', firestore);
      await b.vault.unlock(_uid, _password);
      final report = await b.restore.restore(_uid);

      expect(report.drinks, 1);
      expect(report.exams, 1);
      expect(report.goals, 1);
      expect(report.unreadable, 0);

      final restoredExam = b.exams.getById('exame-1')!;
      expect(restoredExam.age, 47);
      expect(restoredExam.examDate, DateTime(2026, 11, 10, 7, 32, 5));
      expect(restoredExam.examDate.isUtc, isFalse);
      final restoredDrink = b.drinks.getById('drinque-1')!;
      expect(restoredDrink.consumedAt, DateTime(2026, 11, 14, 23, 41, 27));
      expect(restoredDrink.quantity, 2);
      expect(b.goals.getAll().single.target, 7);

      expect(b.queue.pending(), isEmpty);
      expect(b.auditBox.isEmpty, isTrue);
    },
  );

  test('a versão mais recente vence, dos dois lados', () async {
    await deviceWithBackup();
    final b = await _Device.open('b', firestore);
    await b.vault.unlock(_uid, _password);
    await b.exams.restore(exam(updatedAt: DateTime(2026, 11, 20), ast: 99));
    await b.drinks.restore(
      DrinkEntry(
        id: 'drinque-1',
        type: DrinkType.beer,
        volumeMl: 350,
        alcoholPercent: 5,
        quantity: 9,
        consumedAt: DateTime(2026, 11, 14, 23, 41, 27),
        createdAt: created,
        updatedAt: DateTime(2026, 11, 1),
      ),
    );

    final report = await b.restore.restore(_uid);

    expect(b.exams.getById('exame-1')!.ast, 99);
    expect(b.drinks.getById('drinque-1')!.quantity, 2);
    expect(report.exams, 0);
    expect(report.drinks, 1);
  });

  test('exclusão ainda não enviada não é desfeita pela nuvem', () async {
    final a = await deviceWithBackup();
    await a.drinks.delete('drinque-1');

    await a.restore.restore(_uid);

    expect(a.drinks.getById('drinque-1'), isNull);
    expect(a.queue.pending().single.operation, SyncOperation.delete);
  });

  test('o que só existe no aparelho entra na fila para subir', () async {
    await deviceWithBackup();
    final b = await _Device.open('b', firestore);
    await b.vault.unlock(_uid, _password);
    await b.drinks.restore(drink(id: 'so-no-b'));

    await b.restore.restore(_uid);

    final pending = b.queue.pending();
    expect(pending, hasLength(1));
    expect(pending.single.entityId, 'so-no-b');
    expect((await b.send()).sent, 1);
  });

  test(
    'documento antigo, sem a parte selada, é contado e não quebra',
    () async {
      await deviceWithBackup();
      await firestore
          .collection('users')
          .doc(_uid)
          .collection('drinks')
          .doc('antigo')
          .set({'type': 'beer', 'quantity': 1});
      final b = await _Device.open('b', firestore);
      await b.vault.unlock(_uid, _password);

      final report = await b.restore.restore(_uid);

      expect(report.unreadable, 1);
      expect(report.total, 3);
    },
  );

  test('apagar a cópia da nuvem remove os três tipos de registro', () async {
    final a = await deviceWithBackup();

    await a.restore.deleteRemote(_uid);

    final user = firestore.collection('users').doc(_uid);
    for (final collection in ['drinks', 'exams', 'goals']) {
      expect((await user.collection(collection).get()).docs, isEmpty);
    }
  });
}

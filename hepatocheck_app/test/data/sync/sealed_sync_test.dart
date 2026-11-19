import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hepatocheck_app/data/models/firestore_mappers.dart';
import 'package:hepatocheck_app/data/sync/firestore_cloud_vault.dart';
import 'package:hepatocheck_app/data/sync/firestore_sync_remote.dart';
import 'package:hepatocheck_app/domain/entities/sync_item.dart';
import 'package:hepatocheck_app/domain/repositories/cloud_vault.dart';
import 'package:hepatocheck_app/domain/usecases/anonymize_sync_payload.dart';
import 'package:hepatocheck_app/domain/usecases/sync_pending_items.dart';

import '../../support/sync_fakes.dart';
import '../../support/test_data.dart';

void main() {
  const uid = 'uid-1';
  late FakeFirebaseFirestore firestore;
  late MemorySyncQueue queue;
  late FirestoreCloudVault vault;
  late SyncPendingItems sync;

  setUp(() async {
    FlutterSecureStorage.setMockInitialValues({});
    firestore = FakeFirebaseFirestore();
    queue = MemorySyncQueue();
    vault = FirestoreCloudVault(firestore, iterations: 1000);
    sync = SyncPendingItems(
      queue: queue,
      remote: FirestoreSyncRemote(firestore),
      anonymize: const AnonymizeSyncPayload().call,
      seal: (payload) async => (await vault.seal(payload)).toFields(),
      sealReady: () => vault.isUnlocked,
    );
  });

  final exam = testExam(
    id: 'exame-1',
    age: 47,
    ast: 38,
    examDate: DateTime(2026, 11, 10, 7, 32, 5),
  );

  Future<void> enqueueExam() => queue.enqueue(
    entityType: SyncEntityType.exam,
    entityId: exam.id,
    operation: SyncOperation.create,
    payload: FirestoreMappers.examToFirestore(exam),
  );

  Future<Map<String, dynamic>> sentExam() async =>
      (await firestore
              .collection('users')
              .doc(uid)
              .collection('exams')
              .doc(exam.id)
              .get())
          .data()!;

  test('a parte legível continua anonimizada e a selada guarda os valores '
      'exatos', () async {
    await vault.create(uid, 'senha-forte-1');
    await enqueueExam();

    final report = await sync(userId: uid, hasConsent: true, isOnWifi: true);
    final document = await sentExam();

    expect(report.sent, 1);
    expect(document['ageRange'], '40-49');
    expect(document.containsKey('age'), isFalse);
    expect(document['keyVersion'], 1);
    expect(document['sealed'], isA<String>());
    expect(document['sealed'], isNot(contains('47')));

    final opened = await vault.open(SealedData.fromFields(document)!);
    expect(opened['age'], 47);
    expect(opened['examDate'], exam.examDate.toUtc().toIso8601String());
    final restored = FirestoreMappers.examFromFirestore(exam.id, opened);
    expect(restored.age, 47);
    expect(restored.examDate, exam.examDate.toUtc());
  });

  test('com o cofre trancado o envio espera e nada sai do aparelho', () async {
    await enqueueExam();

    final report = await sync(userId: uid, hasConsent: true, isOnWifi: true);

    expect(report.skipped, SyncSkipReason.vaultLocked);
    expect(queue.pending(), hasLength(1));
    expect((await firestore.collection('users').get()).docs, isEmpty);
  });

  test('exclusão não leva conteúdo', () async {
    await vault.create(uid, 'senha-forte-1');
    await enqueueExam();
    await sync(userId: uid, hasConsent: true, isOnWifi: true);

    await queue.enqueue(
      entityType: SyncEntityType.exam,
      entityId: exam.id,
      operation: SyncOperation.delete,
      payload: const {},
    );
    final report = await sync(userId: uid, hasConsent: true, isOnWifi: true);

    expect(report.sent, 1);
    expect(
      (await firestore
              .collection('users')
              .doc(uid)
              .collection('exams')
              .doc(exam.id)
              .get())
          .exists,
      isFalse,
    );
  });
}

import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hepatocheck_app/data/sync/firestore_sync_remote.dart';
import 'package:hepatocheck_app/domain/entities/sync_item.dart';

SyncItem _item(
  String entityId,
  SyncOperation operation, {
  SyncEntityType entityType = SyncEntityType.exam,
  Map<String, dynamic> payload = const {},
}) => SyncItem(
  id: 'item-$entityId',
  entityType: entityType,
  entityId: entityId,
  operation: operation,
  payload: payload,
  createdAt: DateTime(2026, 11, 16),
);

void main() {
  late FakeFirebaseFirestore firestore;
  late FirestoreSyncRemote remote;

  setUp(() {
    firestore = FakeFirebaseFirestore();
    remote = FirestoreSyncRemote(firestore);
  });

  test('grava cada registro na pasta do usuário, na coleção do tipo', () async {
    await remote.sendBatch('usuario-1', [
      _item('exame-1', SyncOperation.create, payload: {'ast': 38}),
      _item(
        'drinque-1',
        SyncOperation.create,
        entityType: SyncEntityType.drink,
        payload: {'quantity': 2},
      ),
      _item(
        'meta-1',
        SyncOperation.create,
        entityType: SyncEntityType.goal,
        payload: {'target': 3},
      ),
    ]);

    final user = firestore.collection('users').doc('usuario-1');
    expect((await user.collection('exams').doc('exame-1').get()).data(), {
      'ast': 38,
    });
    expect((await user.collection('drinks').doc('drinque-1').get()).data(), {
      'quantity': 2,
    });
    expect((await user.collection('goals').doc('meta-1').get()).data(), {
      'target': 3,
    });
  });

  test('atualização substitui o documento e exclusão o remove', () async {
    final exams = firestore
        .collection('users')
        .doc('usuario-1')
        .collection('exams');
    await remote.sendBatch('usuario-1', [
      _item('exame-1', SyncOperation.create, payload: {'ast': 38, 'alt': 40}),
      _item('exame-2', SyncOperation.create, payload: {'ast': 20}),
    ]);

    await remote.sendBatch('usuario-1', [
      _item('exame-1', SyncOperation.update, payload: {'ast': 45}),
      _item('exame-2', SyncOperation.delete),
    ]);

    expect((await exams.doc('exame-1').get()).data(), {'ast': 45});
    expect((await exams.doc('exame-2').get()).exists, isFalse);
  });

  test('dados de um usuário não aparecem na pasta de outro', () async {
    await remote.sendBatch('usuario-1', [
      _item('exame-1', SyncOperation.create, payload: {'ast': 38}),
    ]);

    final other = await firestore
        .collection('users')
        .doc('usuario-2')
        .collection('exams')
        .get();
    expect(other.docs, isEmpty);
  });
}

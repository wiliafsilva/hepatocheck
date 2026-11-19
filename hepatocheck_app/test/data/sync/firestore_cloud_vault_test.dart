import 'dart:convert';

import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hepatocheck_app/data/sync/firestore_cloud_vault.dart';
import 'package:hepatocheck_app/domain/repositories/cloud_vault.dart';

void main() {
  const uid = 'uid-1';
  const password = 'senha-forte-1';
  late FakeFirebaseFirestore firestore;

  FirestoreCloudVault newVault() =>
      FirestoreCloudVault(firestore, iterations: 1000);

  void newDevice() => FlutterSecureStorage.setMockInitialValues({});

  setUp(() {
    firestore = FakeFirebaseFirestore();
    newDevice();
  });

  final exact = {
    'age': 47,
    'ast': 38.0,
    'consumedAt': DateTime.utc(2026, 11, 14, 23, 41, 27),
    'type': 'beer',
  };

  test('sela e abre os valores exatos', () async {
    final vault = newVault();
    await vault.create(uid, password);

    final sealed = await vault.seal(exact);
    final opened = await vault.open(sealed);

    expect(opened['age'], 47);
    expect(opened['ast'], 38.0);
    expect(opened['consumedAt'], '2026-11-14T23:41:27.000Z');
    expect(sealed.sealed, isNot(contains('47')));
    expect(sealed.keyVersion, 1);
  });

  test('outro aparelho abre os dados com a mesma senha', () async {
    final first = newVault();
    await first.create(uid, password);
    final sealed = await first.seal(exact);

    newDevice();
    final second = newVault();
    expect(await second.resume(uid), isFalse);
    await second.unlock(uid, password);

    expect((await second.open(sealed))['age'], 47);
  });

  test('senha errada não abre a chave', () async {
    await newVault().create(uid, password);
    newDevice();

    await expectLater(
      newVault().unlock(uid, 'outra-senha'),
      throwsA(isA<VaultKeyMismatchException>()),
    );
  });

  test('o aparelho reabre o cofre sem pedir a senha de novo', () async {
    final vault = newVault();
    await vault.create(uid, password);
    final sealed = await vault.seal(exact);

    final reopened = newVault();
    expect(await reopened.resume(uid), isTrue);
    expect((await reopened.open(sealed))['age'], 47);
  });

  test('esquecer a chave tranca o cofre neste aparelho', () async {
    final vault = newVault();
    await vault.create(uid, password);
    await vault.forget(uid);

    expect(vault.isUnlocked, isFalse);
    expect(await newVault().resume(uid), isFalse);
    await expectLater(vault.seal(exact), throwsA(isA<VaultLockedException>()));
  });

  test(
    'nova chave depois de recuperar a senha não abre a cópia antiga',
    () async {
      final vault = newVault();
      await vault.create(uid, password);
      final old = await vault.seal(exact);

      await vault.reset(uid, 'senha-nova-1');

      expect(vault.keyVersion, 2);
      await expectLater(
        vault.open(old),
        throwsA(isA<VaultKeyMismatchException>()),
      );
      newDevice();
      final other = newVault();
      await other.unlock(uid, 'senha-nova-1');
      expect(other.keyVersion, 2);
    },
  );

  test('trocar a senha mantém os dados', () async {
    final vault = newVault();
    await vault.create(uid, password);
    final sealed = await vault.seal(exact);

    await vault.rewrap(uid, 'senha-trocada-1');

    newDevice();
    final other = newVault();
    await other.unlock(uid, 'senha-trocada-1');
    expect((await other.open(sealed))['age'], 47);
    newDevice();
    await expectLater(
      newVault().unlock(uid, password),
      throwsA(isA<VaultKeyMismatchException>()),
    );
  });

  test('login sem chave na nuvem cria uma chave nova', () async {
    final vault = newVault();
    await vault.unlock(uid, password);

    expect(vault.isUnlocked, isTrue);
    expect(vault.keyVersion, 1);
    final document = await firestore.collection('users').doc(uid).get();
    expect(document.exists, isTrue);
  });

  test('a nuvem guarda só a chave trancada, nunca a chave aberta', () async {
    final vault = newVault();
    await vault.create(uid, password);
    final stored = await const FlutterSecureStorage().read(
      key: 'cloud_vault_key_$uid',
    );

    final data = (await firestore.collection('users').doc(uid).get()).data()!;

    expect(data.keys.toSet(), {
      'keyVersion',
      'kdf',
      'iterations',
      'salt',
      'wrappedKey',
      'wrapNonce',
      'updatedAt',
    });
    expect(data['kdf'], 'pbkdf2-sha256');
    expect(data['wrappedKey'], isNot(stored));
    expect(jsonEncode(data.toString()), isNot(contains(stored!)));
  });
}

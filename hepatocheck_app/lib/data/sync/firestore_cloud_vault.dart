import 'dart:convert';
import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cryptography/cryptography.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../../domain/repositories/cloud_vault.dart';

class FirestoreCloudVault implements CloudVault {
  FirestoreCloudVault(
    this._firestore, {
    FlutterSecureStorage? storage,
    this.iterations = defaultIterations,
    Random? random,
  }) : _storage = storage ?? const FlutterSecureStorage(),
       _random = random ?? Random.secure();

  static const defaultIterations = 200000;
  static const kdfName = 'pbkdf2-sha256';
  static const _macLength = 16;

  final FirebaseFirestore _firestore;
  final FlutterSecureStorage _storage;
  final Random _random;
  final int iterations;
  final _aes = AesGcm.with256bits();

  List<int>? _dataKey;
  int? _keyVersion;

  @override
  bool get isUnlocked => _dataKey != null;

  @override
  int? get keyVersion => _keyVersion;

  DocumentReference<Map<String, dynamic>> _keyDocument(String uid) =>
      _firestore.collection('users').doc(uid);

  static String _keyName(String uid) => 'cloud_vault_key_$uid';

  static String _versionName(String uid) => 'cloud_vault_version_$uid';

  List<int> _randomBytes(int length) =>
      List<int>.generate(length, (_) => _random.nextInt(256));

  Future<SecretKey> _passwordKey(String password, List<int> salt, int rounds) =>
      Pbkdf2(
        macAlgorithm: Hmac.sha256(),
        iterations: rounds,
        bits: 256,
      ).deriveKeyFromPassword(password: password, nonce: salt);

  Future<(String, String)> _encrypt(List<int> clear, List<int> key) async {
    final box = await _aes.encrypt(clear, secretKey: SecretKey(key));
    return (
      base64Encode(box.concatenation(nonce: false)),
      base64Encode(box.nonce),
    );
  }

  Future<List<int>> _decrypt(String data, String nonce, SecretKey key) async {
    final bytes = base64Decode(data);
    if (bytes.length < _macLength) throw const VaultKeyMismatchException();
    final box = SecretBox(
      bytes.sublist(0, bytes.length - _macLength),
      nonce: base64Decode(nonce),
      mac: Mac(bytes.sublist(bytes.length - _macLength)),
    );
    try {
      return await _aes.decrypt(box, secretKey: key);
    } on SecretBoxAuthenticationError {
      throw const VaultKeyMismatchException();
    }
  }

  Future<void> _writeKeyDocument(
    String uid,
    String password,
    List<int> dataKey,
    int version,
  ) async {
    final salt = _randomBytes(16);
    final passwordKey = await _passwordKey(password, salt, iterations);
    final (wrapped, nonce) = await _encrypt(
      dataKey,
      await passwordKey.extractBytes(),
    );
    await _keyDocument(uid).set({
      'keyVersion': version,
      'kdf': kdfName,
      'iterations': iterations,
      'salt': base64Encode(salt),
      'wrappedKey': wrapped,
      'wrapNonce': nonce,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> _keep(String uid, List<int> dataKey, int version) async {
    _dataKey = dataKey;
    _keyVersion = version;
    await _storage.write(key: _keyName(uid), value: base64Encode(dataKey));
    await _storage.write(key: _versionName(uid), value: '$version');
  }

  @override
  Future<void> create(String uid, String password) async {
    final dataKey = _randomBytes(32);
    await _writeKeyDocument(uid, password, dataKey, 1);
    await _keep(uid, dataKey, 1);
  }

  @override
  Future<void> unlock(String uid, String password) async {
    final snapshot = await _keyDocument(uid).get();
    final data = snapshot.data();
    if (data == null || data['wrappedKey'] == null) {
      await create(uid, password);
      return;
    }
    final passwordKey = await _passwordKey(
      password,
      base64Decode(data['salt'] as String),
      (data['iterations'] as num).toInt(),
    );
    final dataKey = await _decrypt(
      data['wrappedKey'] as String,
      data['wrapNonce'] as String,
      passwordKey,
    );
    await _keep(uid, dataKey, (data['keyVersion'] as num).toInt());
  }

  @override
  Future<bool> resume(String uid) async {
    final key = await _storage.read(key: _keyName(uid));
    final version = int.tryParse(
      await _storage.read(key: _versionName(uid)) ?? '',
    );
    if (key == null || version == null) return false;
    _dataKey = base64Decode(key);
    _keyVersion = version;
    return true;
  }

  @override
  Future<void> reset(String uid, String password) async {
    final snapshot = await _keyDocument(uid).get();
    final previous = (snapshot.data()?['keyVersion'] as num?)?.toInt() ?? 0;
    final dataKey = _randomBytes(32);
    await _writeKeyDocument(uid, password, dataKey, previous + 1);
    await _keep(uid, dataKey, previous + 1);
  }

  @override
  Future<void> rewrap(String uid, String newPassword) async {
    final dataKey = _dataKey;
    final version = _keyVersion;
    if (dataKey == null || version == null) throw const VaultLockedException();
    await _writeKeyDocument(uid, newPassword, dataKey, version);
  }

  @override
  Future<void> lock() async {
    _dataKey = null;
    _keyVersion = null;
  }

  @override
  Future<void> forget(String uid) async {
    await lock();
    await _storage.delete(key: _keyName(uid));
    await _storage.delete(key: _versionName(uid));
  }

  @override
  Future<SealedData> seal(Map<String, dynamic> data) async {
    final dataKey = _dataKey;
    final version = _keyVersion;
    if (dataKey == null || version == null) throw const VaultLockedException();
    final clear = utf8.encode(jsonEncode(_jsonSafe(data)));
    final (sealed, nonce) = await _encrypt(clear, dataKey);
    return SealedData(sealed: sealed, nonce: nonce, keyVersion: version);
  }

  @override
  Future<Map<String, dynamic>> open(SealedData data) async {
    final dataKey = _dataKey;
    if (dataKey == null) throw const VaultLockedException();
    if (data.keyVersion != _keyVersion) {
      throw const VaultKeyMismatchException();
    }
    final clear = await _decrypt(data.sealed, data.nonce, SecretKey(dataKey));
    return Map<String, dynamic>.from(jsonDecode(utf8.decode(clear)) as Map);
  }

  static Object? _jsonSafe(Object? value) => switch (value) {
    DateTime() => value.toUtc().toIso8601String(),
    Map() => {
      for (final entry in value.entries) '${entry.key}': _jsonSafe(entry.value),
    },
    List() => [for (final item in value) _jsonSafe(item)],
    _ => value,
  };
}

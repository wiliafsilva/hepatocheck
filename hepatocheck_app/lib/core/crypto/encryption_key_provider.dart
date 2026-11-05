import 'dart:convert';
import 'dart:math';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class EncryptionKeyProvider {
  EncryptionKeyProvider({FlutterSecureStorage? storage})
      : _storage = storage ?? const FlutterSecureStorage();

  static const _storageKey = 'hive_encryption_key';
  static const _keyLength = 32;

  final FlutterSecureStorage _storage;

  Future<List<int>> getOrCreateKey() async {
    final stored = await _storage.read(key: _storageKey);
    if (stored != null) {
      return base64Url.decode(stored);
    }

    final random = Random.secure();
    final key = List<int>.generate(_keyLength, (_) => random.nextInt(256));
    await _storage.write(key: _storageKey, value: base64UrlEncode(key));
    return key;
  }
}

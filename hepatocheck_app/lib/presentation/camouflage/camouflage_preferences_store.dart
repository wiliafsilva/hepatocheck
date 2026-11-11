import 'dart:convert';
import 'dart:math';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../../core/security/secret_code_hasher.dart';

class CamouflagePreferencesStore {
  CamouflagePreferencesStore({FlutterSecureStorage? storage})
    : _storage = storage ?? const FlutterSecureStorage();

  static const _enabledKey = 'camouflage_enabled';
  static const _codeHashKey = 'camouflage_code_hash';
  static const _verificationKey = 'camouflage_verification_key';

  final FlutterSecureStorage _storage;

  Future<bool> isEnabled() async =>
      await _storage.read(key: _enabledKey) == 'true';

  Future<void> enable(String code) async {
    final key = await _newVerificationKey();
    await _storage.write(key: _verificationKey, value: key);
    await _storage.write(
      key: _codeHashKey,
      value: SecretCodeHasher.keyedHash(code: code, key: key),
    );
    await _storage.write(key: _enabledKey, value: 'true');
  }

  Future<bool> matchesCode(String code) async {
    final hash = await _storage.read(key: _codeHashKey);
    if (hash == null) return false;

    final key = await _storage.read(key: _verificationKey);
    if (key == null) {
      final matchesLegacyHash = hash == SecretCodeHasher.hash(code);
      if (matchesLegacyHash) await enable(code);
      return matchesLegacyHash;
    }
    return hash == SecretCodeHasher.keyedHash(code: code, key: key);
  }

  Future<void> disable() async {
    await _storage.delete(key: _enabledKey);
    await _storage.delete(key: _codeHashKey);
    await _storage.delete(key: _verificationKey);
  }

  Future<String> _newVerificationKey() async {
    final random = Random.secure();
    final bytes = List<int>.generate(32, (_) => random.nextInt(256));
    return base64UrlEncode(bytes);
  }
}

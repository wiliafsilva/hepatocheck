import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../../core/security/secret_code_hasher.dart';

class CamouflagePreferencesStore {
  CamouflagePreferencesStore({FlutterSecureStorage? storage})
    : _storage = storage ?? const FlutterSecureStorage();

  static const _enabledKey = 'camouflage_enabled';
  static const _codeHashKey = 'camouflage_code_hash';

  final FlutterSecureStorage _storage;

  Future<bool> isEnabled() async =>
      await _storage.read(key: _enabledKey) == 'true';

  Future<void> enable(String code) async {
    await _storage.write(key: _codeHashKey, value: SecretCodeHasher.hash(code));
    await _storage.write(key: _enabledKey, value: 'true');
  }

  Future<bool> matchesCode(String code) async {
    final hash = await _storage.read(key: _codeHashKey);
    return hash != null && hash == SecretCodeHasher.hash(code);
  }

  Future<void> disable() async {
    await _storage.delete(key: _enabledKey);
    await _storage.delete(key: _codeHashKey);
  }
}

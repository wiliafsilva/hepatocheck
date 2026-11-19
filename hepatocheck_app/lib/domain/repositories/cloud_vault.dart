class VaultLockedException implements Exception {
  const VaultLockedException();

  @override
  String toString() => 'VaultLockedException';
}

class VaultKeyMismatchException implements Exception {
  const VaultKeyMismatchException();

  @override
  String toString() => 'VaultKeyMismatchException';
}

class SealedData {
  const SealedData({
    required this.sealed,
    required this.nonce,
    required this.keyVersion,
  });

  static const sealedField = 'sealed';
  static const nonceField = 'sealedNonce';
  static const versionField = 'keyVersion';

  final String sealed;
  final String nonce;
  final int keyVersion;

  Map<String, dynamic> toFields() => {
    sealedField: sealed,
    nonceField: nonce,
    versionField: keyVersion,
  };

  static SealedData? fromFields(Map<String, dynamic> data) {
    final sealed = data[sealedField];
    final nonce = data[nonceField];
    final version = data[versionField];
    if (sealed is! String || nonce is! String || version is! num) return null;
    return SealedData(
      sealed: sealed,
      nonce: nonce,
      keyVersion: version.toInt(),
    );
  }
}

abstract interface class CloudVault {
  bool get isUnlocked;

  int? get keyVersion;

  Future<void> create(String uid, String password);

  Future<void> unlock(String uid, String password);

  Future<bool> resume(String uid);

  Future<void> reset(String uid, String password);

  Future<void> rewrap(String uid, String newPassword);

  Future<void> lock();

  Future<void> forget(String uid);

  Future<SealedData> seal(Map<String, dynamic> data);

  Future<Map<String, dynamic>> open(SealedData data);
}

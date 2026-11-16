import 'package:hive_ce/hive.dart';

import '../../domain/repositories/sync_consent_repository.dart';

class HiveSyncConsentRepository implements SyncConsentRepository {
  HiveSyncConsentRepository(this._box);

  static const grantedAtKey = 'granted_at';

  final Box<String> _box;

  @override
  DateTime? get grantedAt {
    final value = _box.get(grantedAtKey);
    return value == null ? null : DateTime.tryParse(value);
  }

  @override
  bool get isGranted => grantedAt != null;

  @override
  Future<void> grant(DateTime at) async {
    await _box.put(grantedAtKey, at.toIso8601String());
    await _box.flush();
  }

  @override
  Future<void> revoke() async {
    await _box.delete(grantedAtKey);
    await _box.flush();
  }
}

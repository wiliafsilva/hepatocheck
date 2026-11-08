import 'package:flutter/foundation.dart';

import '../../data/datasources/local/hive_database.dart';
import 'camouflage_preferences_store.dart';

class CamouflageController extends ChangeNotifier {
  CamouflageController(this._preferences);

  final CamouflagePreferencesStore _preferences;

  bool _isEnabled = false;
  bool _isLocked = false;

  bool get isEnabled => _isEnabled;
  bool get isLocked => _isLocked;

  Future<void> load() async {
    _isEnabled = await _preferences.isEnabled();
    _isLocked = _isEnabled;
    notifyListeners();
  }

  Future<void> enable(String code) async {
    await HiveDatabase.ensureEncrypted();
    await _preferences.enable(code);
    _isEnabled = true;
    _isLocked = true;
    notifyListeners();
  }

  Future<bool> unlock(String code) async {
    if (!await _preferences.matchesCode(code)) return false;

    _isLocked = false;
    notifyListeners();
    return true;
  }

  void lockForBackground() {
    if (!_isEnabled || _isLocked) return;
    _isLocked = true;
    notifyListeners();
  }

  Future<void> disable() async {
    await _preferences.disable();
    _isEnabled = false;
    _isLocked = false;
    notifyListeners();
  }
}

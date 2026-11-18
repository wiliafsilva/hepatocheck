import 'package:flutter_riverpod/flutter_riverpod.dart';

final privacyLockPauseProvider = NotifierProvider<PrivacyLockPause, int>(
  PrivacyLockPause.new,
);

class PrivacyLockPause extends Notifier<int> {
  @override
  int build() => 0;

  bool get isPaused => state > 0;

  Future<T> during<T>(Future<T> Function() action) async {
    state = state + 1;
    try {
      return await action();
    } finally {
      state = state - 1;
    }
  }
}

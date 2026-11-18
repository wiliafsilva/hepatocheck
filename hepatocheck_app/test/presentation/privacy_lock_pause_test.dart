import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hepatocheck_app/presentation/camouflage/privacy_lock_pause.dart';

void main() {
  test('pausa o bloqueio só enquanto a ação está aberta', () async {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final pause = container.read(privacyLockPauseProvider.notifier);
    final open = Completer<void>();

    final running = pause.during(() => open.future);
    expect(pause.isPaused, isTrue);

    open.complete();
    await running;
    expect(pause.isPaused, isFalse);
  });

  test('volta ao normal mesmo quando a ação falha', () async {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final pause = container.read(privacyLockPauseProvider.notifier);

    await expectLater(
      pause.during<void>(() async => throw StateError('falhou')),
      throwsStateError,
    );
    expect(pause.isPaused, isFalse);
  });
}

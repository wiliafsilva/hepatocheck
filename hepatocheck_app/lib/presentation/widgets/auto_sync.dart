import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/auth_providers.dart';
import '../providers/consent_providers.dart';
import '../providers/drink_providers.dart';
import '../providers/exam_providers.dart';
import '../providers/goal_providers.dart';
import '../providers/sync_providers.dart';

class AutoSync extends ConsumerStatefulWidget {
  const AutoSync({
    super.key,
    required this.child,
    this.delay = const Duration(seconds: 2),
  });

  final Widget child;
  final Duration delay;

  @override
  ConsumerState<AutoSync> createState() => _AutoSyncState();
}

class _AutoSyncState extends ConsumerState<AutoSync>
    with WidgetsBindingObserver {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _timer?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _schedule();
  }

  void _schedule() {
    _timer?.cancel();
    _timer = Timer(widget.delay, _run);
  }

  Future<void> _run() async {
    if (!mounted || ref.read(isOnWifiProvider).value != true) return;
    try {
      await ref.read(syncStatusProvider.notifier).syncNow();
    } catch (_) {
      return;
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(isOnWifiProvider, (previous, next) {
      if (next.value == true && previous?.value != true) _schedule();
    });
    ref.listen(drinksProvider, (_, _) => _schedule());
    ref.listen(examsProvider, (_, _) => _schedule());
    ref.listen(goalsProvider, (_, _) => _schedule());
    ref.listen(authStateProvider, (previous, next) {
      if (next.value?.uid == previous?.value?.uid) return;
      ref.read(syncStatusProvider.notifier).clearMessage();
      if (next.value != null) _schedule();
    });
    ref.listen(syncConsentControllerProvider, (previous, next) {
      if (next == previous) return;
      ref.read(syncStatusProvider.notifier).clearMessage();
      if (next) _schedule();
    });
    return widget.child;
  }
}

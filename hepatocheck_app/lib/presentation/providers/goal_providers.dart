import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/datasources/local/hive_database.dart';
import '../../data/repositories/hive_goal_repository.dart';
import '../../data/notifications/local_follow_up_notifications.dart';
import '../../domain/entities/reduction_goal.dart';
import '../../domain/entities/follow_up_settings.dart';
import '../../domain/repositories/goal_repository.dart';
import '../../domain/usecases/build_follow_up_messages.dart';
import 'drink_providers.dart';
import 'exam_providers.dart';
import 'report_providers.dart';
import 'sync_providers.dart';

final goalRepositoryProvider = Provider<GoalRepository>(
  (ref) => HiveGoalRepository(
    HiveDatabase.goals,
    ref.watch(syncQueueRepositoryProvider),
  ),
);
final goalsProvider = NotifierProvider<GoalsNotifier, List<ReductionGoal>>(
  GoalsNotifier.new,
);

class GoalsNotifier extends Notifier<List<ReductionGoal>> {
  @override
  List<ReductionGoal> build() => ref.read(goalRepositoryProvider).getAll();

  Future<void> save(ReductionGoal goal) async {
    final repository = ref.read(goalRepositoryProvider);
    await repository.save(goal);
    state = repository.getAll();
  }

  Future<void> delete(String id) async {
    final repository = ref.read(goalRepositoryProvider);
    await repository.delete(id);
    state = repository.getAll();
  }
}

final followUpSettingsProvider =
    NotifierProvider<FollowUpSettingsNotifier, FollowUpSettings>(
      FollowUpSettingsNotifier.new,
    );

class FollowUpSettingsNotifier extends Notifier<FollowUpSettings> {
  @override
  FollowUpSettings build() {
    final saved = HiveDatabase.followUp.get('settings');
    return saved == null
        ? const FollowUpSettings()
        : FollowUpSettings.fromJson(jsonDecode(saved));
  }

  Future<void> save(FollowUpSettings settings) async {
    await HiveDatabase.followUp.put('settings', jsonEncode(settings.toJson()));
    state = settings;
  }
}

final followUpNowProvider = NotifierProvider<FollowUpNow, DateTime>(
  FollowUpNow.new,
);

class FollowUpNow extends Notifier<DateTime> {
  @override
  DateTime build() => ref.read(clockProvider)();
  void refresh() => state = ref.read(clockProvider)();
}

final followUpMessagesProvider = Provider<List<FollowUpMessage>>(
  (ref) => buildFollowUpMessages(
    ref.watch(drinksProvider),
    ref.watch(examsProvider),
    ref.watch(goalsProvider),
    ref.watch(followUpNowProvider),
    settings: ref.watch(followUpSettingsProvider),
    trackingStartedAt: DateTime.tryParse(
      HiveDatabase.followUp.get('tracking_started_at') ?? '',
    ),
  ),
);

final localFollowUpProvider = Provider(
  (ref) => LocalFollowUpNotifications(HiveDatabase.followUp),
);

final notificationStatusProvider =
    NotifierProvider<NotificationStatus, String?>(NotificationStatus.new);

class NotificationStatus extends Notifier<String?> {
  @override
  String? build() => null;
  void setMessage(String? message) => state = message;
}

/// Atualiza os agendamentos após alterações, ao voltar ao app e a cada novo dia.
class FollowUpCoordinator extends ConsumerStatefulWidget {
  const FollowUpCoordinator({super.key, required this.child});
  final Widget child;
  @override
  ConsumerState<FollowUpCoordinator> createState() =>
      _FollowUpCoordinatorState();
}

class _FollowUpCoordinatorState extends ConsumerState<FollowUpCoordinator>
    with WidgetsBindingObserver {
  Timer? _timer, _debounce;
  Future<void> _pending = Future.value();
  DateTime _lastDay = DateUtils.dateOnly(DateTime.now());

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) => _refresh());
    _timer = Timer.periodic(const Duration(minutes: 1), (_) {
      ref.read(followUpNowProvider.notifier).refresh();
      final day = DateUtils.dateOnly(DateTime.now());
      if (day != _lastDay) {
        _lastDay = day;
        _refresh();
      }
    });
  }

  void _refresh() {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 250), () {
      if (!mounted) return;
      final service = ref.read(localFollowUpProvider);
      final settings = ref.read(followUpSettingsProvider);
      final messages = ref.read(followUpMessagesProvider);
      final drinks = ref.read(drinksProvider);
      final exams = ref.read(examsProvider);
      _pending = _pending.then((_) async {
        if (!mounted) return;
        try {
          final status = await service.refresh(
            settings,
            messages,
            drinks,
            exams: exams,
          );
          if (mounted) {
            ref.read(notificationStatusProvider.notifier).setMessage(status);
          }
        } catch (_) {
          if (mounted) {
            ref
                .read(notificationStatusProvider.notifier)
                .setMessage(
                  'Não foi possível atualizar os avisos. Confira as permissões do aparelho e salve as preferências novamente.',
                );
          }
        }
      });
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      ref.read(followUpNowProvider.notifier).refresh();
      _refresh();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _timer?.cancel();
    _debounce?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(localFollowUpProvider, (_, _) => _refresh());
    ref.listen(goalsProvider, (_, _) => _refresh());
    ref.listen(drinksProvider, (_, _) => _refresh());
    ref.listen(examsProvider, (_, _) => _refresh());
    ref.listen(followUpSettingsProvider, (_, _) => _refresh());
    return widget.child;
  }
}

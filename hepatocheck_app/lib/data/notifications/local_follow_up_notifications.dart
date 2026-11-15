import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:hive_ce/hive.dart';
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

import '../../domain/entities/drink_entry.dart';
import '../../domain/entities/lab_exam.dart';
import '../../domain/entities/follow_up_settings.dart';
import '../../domain/usecases/build_follow_up_messages.dart';
import '../../presentation/camouflage/camouflage_preferences_store.dart';

class LocalFollowUpNotifications {
  LocalFollowUpNotifications(this.store, {DateTime Function()? now})
    : _now = now ?? DateTime.now;
  final DateTime Function() _now;
  final Box<String> store;
  final _plugin = FlutterLocalNotificationsPlugin();
  bool _ready = false;

  bool get supported =>
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.android ||
          defaultTargetPlatform == TargetPlatform.iOS);

  static const _details = NotificationDetails(
    android: AndroidNotificationDetails(
      'follow_up',
      'Acompanhamento',
      channelDescription: 'Metas e lembretes configurados por você',
      importance: Importance.defaultImportance,
      priority: Priority.defaultPriority,
      visibility: NotificationVisibility.private,
    ),
    iOS: DarwinNotificationDetails(),
  );

  Future<void> _initialize() async {
    if (_ready) return;
    tz_data.initializeTimeZones();
    await _plugin.initialize(
      settings: const InitializationSettings(
        android: AndroidInitializationSettings('ic_notification'),
        iOS: DarwinInitializationSettings(
          requestAlertPermission: false,
          requestBadgePermission: false,
          requestSoundPermission: false,
        ),
      ),
    );
    _ready = true;
  }

  Future<bool> requestPermission() async {
    if (!supported) return false;
    await _initialize();
    if (defaultTargetPlatform == TargetPlatform.android) {
      return await _plugin
              .resolvePlatformSpecificImplementation<
                AndroidFlutterLocalNotificationsPlugin
              >()
              ?.requestNotificationsPermission() ??
          false;
    }
    return await _plugin
            .resolvePlatformSpecificImplementation<
              IOSFlutterLocalNotificationsPlugin
            >()
            ?.requestPermissions(alert: true, badge: true, sound: true) ??
        false;
  }

  Future<void> _schedule(
    int id,
    String title,
    String body,
    DateTime date, {
    bool daily = false,
  }) => _plugin.zonedSchedule(
    id: id,
    title: title,
    body: body,
    scheduledDate: tz.TZDateTime.from(date, tz.local),
    notificationDetails: _details,
    androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
    matchDateTimeComponents: daily ? DateTimeComponents.time : null,
  );

  Future<String?> refresh(
    FollowUpSettings settings,
    List<FollowUpMessage> messages,
    List<DrinkEntry> drinks, {
    List<LabExam> exams = const [],
  }) async {
    if (!supported) {
      return 'As mensagens ficam disponíveis nesta tela. Os avisos fora do app precisam ser testados no Android ou iPhone.';
    }
    await _initialize();
    final zone = await FlutterTimezone.getLocalTimezone();
    tz.setLocalLocation(tz.getLocation(zone.identifier));
    final now = tz.TZDateTime.from(_now(), tz.local);
    final private = await CamouflagePreferencesStore().isEnabled();
    String body(String value) => private
        ? 'Você tem uma atualização de acompanhamento. Abra o aplicativo para consultar.'
        : value;
    String title(String value) => private ? 'Lembrete' : value;
    // IDs exclusivos deste módulo. Outros avisos do app são preservados.
    for (final id in [3300, 3301, 3302, 3303]) {
      await _plugin.cancel(id: id);
    }
    if (settings.education || settings.registration || settings.exam) {
      final allowed = defaultTargetPlatform == TargetPlatform.android
          ? await _plugin
                .resolvePlatformSpecificImplementation<
                  AndroidFlutterLocalNotificationsPlugin
                >()
                ?.areNotificationsEnabled()
          : (await _plugin
                    .resolvePlatformSpecificImplementation<
                      IOSFlutterLocalNotificationsPlugin
                    >()
                    ?.checkPermissions())
                ?.isEnabled;
      if (allowed != true) {
        return 'As notificações estão bloqueadas. Autorize os avisos nas configurações do aparelho.';
      }
    }
    var next = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      settings.hour,
      settings.minute,
    );
    if (!next.isAfter(now)) {
      next = tz.TZDateTime(
        tz.local,
        now.year,
        now.month,
        now.day + 1,
        settings.hour,
        settings.minute,
      );
    }
    if (settings.education) {
      final education = messages.firstWhere(
        (message) => message.key == 'education',
      );
      await _schedule(
        3300,
        title(education.title),
        body(education.body),
        next,
        daily: true,
      );
    }
    if (settings.registration) {
      final last = drinks.isEmpty
          ? DateTime.tryParse(store.get('tracking_started_at') ?? '') ?? now
          : drinks
                .map((e) => e.updatedAt)
                .reduce((a, b) => a.isAfter(b) ? a : b);
      // A data inicial respeita três dias sem registrar consumo.
      var first = next;
      final due = tz.TZDateTime(
        tz.local,
        last.year,
        last.month,
        last.day + 3,
        settings.hour,
        settings.minute,
      );
      if (due.isAfter(first)) first = due;
      await _schedule(
        3301,
        title('Atualize seu diário'),
        body('Reserve um momento para conferir e atualizar seus registros.'),
        first,
      );
    }
    final exam = nextExamDate(settings, exams);
    if (settings.exam && exam != null) {
      await _schedule(
        3302,
        title('Lembrete de exame'),
        body(
          exam.isAfter(now)
              ? 'Você programou um lembrete de exame para hoje.'
              : messages
                    .firstWhere(
                      (m) => m.key == 'exam-info',
                      orElse: () => const FollowUpMessage(
                        'exam-info',
                        'Exame',
                        'A data de acompanhamento configurada chegou. Converse com seu médico sobre repetir.',
                      ),
                    )
                    .body,
        ),
        exam.isAfter(now) ? exam : next,
      );
    }
    // Feedback único por meta, semana e situação. A preferência educativa
    // também controla avisos de progresso fora do app.
    if (settings.education) {
      for (final message in messages.where(
        (m) =>
            m.key.startsWith('goal-') &&
            (m.key.endsWith('-achieved') ||
                m.key.endsWith('-nearLimit') ||
                m.key.endsWith('-exceeded')),
      )) {
        final key = 'sent-${message.key}';
        if (store.containsKey(key)) continue;
        await _plugin.show(
          id: 3303,
          title: title(message.title),
          body: body(message.body),
          notificationDetails: _details,
        );
        await store.put(key, now.toIso8601String());
      }
    }
    return null;
  }
}

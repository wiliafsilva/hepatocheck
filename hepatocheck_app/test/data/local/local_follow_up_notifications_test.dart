import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce/hive.dart';
import 'package:hepatocheck_app/data/notifications/local_follow_up_notifications.dart';
import 'package:hepatocheck_app/domain/entities/follow_up_settings.dart';
import 'package:hepatocheck_app/domain/usecases/build_follow_up_messages.dart';

import '../../support/test_data.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const channel = MethodChannel('dexterous.com/flutter/local_notifications');
  const timezone = MethodChannel('flutter_timezone');
  late Directory directory;
  late Box<String> box;
  late List<MethodCall> calls;
  var allowed = true;
  final now = DateTime(2026, 11, 14, 12);

  setUp(() async {
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    AndroidFlutterLocalNotificationsPlugin.registerWith();
    FlutterSecureStorage.setMockInitialValues({'camouflage_enabled': 'true'});
    directory = await Directory.systemTemp.createTemp('notification-tests');
    Hive.init(directory.path);
    box = await Hive.openBox<String>('settings');
    calls = [];
    allowed = true;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
          calls.add(call);
          if (call.method == 'areNotificationsEnabled') return allowed;
          if (call.method == 'initialize') return true;
          return null;
        });
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          timezone,
          (_) async => {'identifier': 'America/Sao_Paulo'},
        );
  });
  tearDown(() async {
    debugDefaultTargetPlatformOverride = null;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(timezone, null);
    await Hive.close();
    await directory.delete(recursive: true);
  });

  test(
    'agenda localmente e preserva privacidade; registro aguarda três dias',
    () async {
      final service = LocalFollowUpNotifications(box, now: () => now);
      await service.refresh(
        const FollowUpSettings(education: true, registration: true),
        const [FollowUpMessage('education', 'Diário', 'Conteúdo sensível')],
        [testDrink(1, now)],
      );
      final scheduled = calls
          .where((c) => c.method == 'zonedSchedule')
          .toList();
      expect(scheduled.length, 2);
      for (final call in scheduled) {
        final arguments = call.arguments as Map;
        expect(arguments['body'], isNot(contains('Conteúdo sensível')));
        expect(arguments['title'], 'Lembrete');
      }
      final registration =
          scheduled
                  .firstWhere((c) => (c.arguments as Map)['id'] == 3301)
                  .arguments
              as Map;
      expect(registration['scheduledDateTime'], startsWith('2026-11-17'));
      expect(registration['matchDateTimeComponents'], isNull);
    },
  );

  test('desligar avisos cancela agendamentos deste módulo', () async {
    final service = LocalFollowUpNotifications(box, now: () => now);
    await service.refresh(const FollowUpSettings(), [], []);
    expect(calls.where((c) => c.method == 'cancel').length, 4);
    expect(calls.where((c) => c.method == 'zonedSchedule'), isEmpty);
  });

  test(
    'permissão negada retorna aviso e não marca feedback como enviado',
    () async {
      allowed = false;
      final service = LocalFollowUpNotifications(box, now: () => now);
      final status = await service.refresh(
        const FollowUpSettings(education: true),
        const [FollowUpMessage('goal-1-achieved', 'Meta', 'Cumprida')],
        [],
      );
      expect(status, contains('bloqueadas'));
      expect(calls.where((c) => c.method == 'show'), isEmpty);
      expect(box.isEmpty, isTrue);
    },
  );

  test('feedback é emitido uma vez por meta e situação', () async {
    final service = LocalFollowUpNotifications(box, now: () => now);
    const messages = [
      FollowUpMessage('education', 'Dica', 'Atualize o diário'),
      FollowUpMessage('goal-1-achieved', 'Meta', 'Cumprida'),
    ];
    await service.refresh(
      const FollowUpSettings(education: true),
      messages,
      [],
    );
    await service.refresh(
      const FollowUpSettings(education: true),
      messages,
      [],
    );
    expect(calls.where((c) => c.method == 'show').length, 1);
  });
}

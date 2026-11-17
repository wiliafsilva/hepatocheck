import 'package:hive_ce_flutter/hive_ce_flutter.dart';

import '../../../core/crypto/encryption_key_provider.dart';
import '../../../domain/entities/audit_entry.dart';
import '../../../domain/entities/drink_entry.dart';
import '../../../domain/entities/lab_exam.dart';
import '../../../domain/entities/sync_item.dart';
import '../../models/hive_registrar.g.dart';

abstract final class HiveDatabase {
  static const drinksBoxName = 'drinks';
  static const examsBoxName = 'exams';
  static const syncQueueBoxName = 'sync_queue';
  static const auditLogBoxName = 'audit_log';

  static const syncConsentBoxName = 'sync_consent';
  static Box<String> get syncConsent =>
      Hive.box<String>(syncConsentBoxName);

  static const goalsBoxName = 'reduction_goals';
  static const followUpBoxName = 'follow_up_preferences';
  static Box<String> get goals => Hive.box<String>(goalsBoxName);
  static Box<String> get followUp => Hive.box<String>(followUpBoxName);
  static const trackingStartedAtKey = 'tracking_started_at';

  static Future<void> markTrackingStarted() =>
      followUp.put(trackingStartedAtKey, DateTime.now().toIso8601String());

  static bool _encryptionReady = false;

  static Future<void> init(EncryptionKeyProvider keyProvider) async {
    await Hive.initFlutter();
    Hive.registerAdapters();

    final cipher = HiveAesCipher(await keyProvider.getOrCreateKey());
    await Hive.openBox<DrinkEntry>(drinksBoxName, encryptionCipher: cipher);
    await Hive.openBox<LabExam>(examsBoxName, encryptionCipher: cipher);
    await Hive.openBox<SyncItem>(syncQueueBoxName, encryptionCipher: cipher);
    await Hive.openBox<AuditEntry>(auditLogBoxName, encryptionCipher: cipher);
    await Hive.openBox<String>(goalsBoxName, encryptionCipher: cipher);
    await Hive.openBox<String>(followUpBoxName, encryptionCipher: cipher);
    await Hive.openBox<String>(syncConsentBoxName, encryptionCipher: cipher);
    if (!followUp.containsKey(trackingStartedAtKey)) {
      await markTrackingStarted();
    }
    _encryptionReady = true;
  }

  /// As caixas são abertas com AES-256 desde a fundação do aplicativo.
  ///
  /// A chamada ao ativar a camuflagem é uma garantia explícita de que dados
  /// existentes já foram gravados usando o cipher antes de a tela sensível ser
  /// ocultada. Em instalações legadas, a migração deve ocorrer antes de abrir
  /// as caixas para que nenhum dado seja exposto entre a leitura e a regravação.
  static Future<void> ensureEncrypted() async {
    if (!_encryptionReady) {
      throw StateError(
        'O banco Hive ainda não foi inicializado com criptografia.',
      );
    }
    await Future.wait([
      drinks.flush(),
      exams.flush(),
      syncQueue.flush(),
      auditLog.flush(),
      goals.flush(),
      followUp.flush(),
      syncConsent.flush(),
    ]);
  }

  static Box<DrinkEntry> get drinks => Hive.box<DrinkEntry>(drinksBoxName);

  static Box<LabExam> get exams => Hive.box<LabExam>(examsBoxName);

  static Box<SyncItem> get syncQueue => Hive.box<SyncItem>(syncQueueBoxName);

  static Box<AuditEntry> get auditLog => Hive.box<AuditEntry>(auditLogBoxName);
}

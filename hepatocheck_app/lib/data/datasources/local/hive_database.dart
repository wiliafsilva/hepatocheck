import 'package:hive_ce_flutter/hive_ce_flutter.dart';

import '../../../core/crypto/encryption_key_provider.dart';
import '../../../domain/entities/drink_entry.dart';
import '../../../domain/entities/lab_exam.dart';
import '../../../domain/entities/sync_item.dart';
import '../../models/hive_registrar.g.dart';

abstract final class HiveDatabase {
  static const drinksBoxName = 'drinks';
  static const examsBoxName = 'exams';
  static const syncQueueBoxName = 'sync_queue';

  static bool _encryptionReady = false;

  static Future<void> init(EncryptionKeyProvider keyProvider) async {
    await Hive.initFlutter();
    Hive.registerAdapters();

    final cipher = HiveAesCipher(await keyProvider.getOrCreateKey());
    await Hive.openBox<DrinkEntry>(drinksBoxName, encryptionCipher: cipher);
    await Hive.openBox<LabExam>(examsBoxName, encryptionCipher: cipher);
    await Hive.openBox<SyncItem>(syncQueueBoxName, encryptionCipher: cipher);
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
    await Future.wait([drinks.flush(), exams.flush(), syncQueue.flush()]);
  }

  static Box<DrinkEntry> get drinks => Hive.box<DrinkEntry>(drinksBoxName);

  static Box<LabExam> get exams => Hive.box<LabExam>(examsBoxName);

  static Box<SyncItem> get syncQueue => Hive.box<SyncItem>(syncQueueBoxName);
}

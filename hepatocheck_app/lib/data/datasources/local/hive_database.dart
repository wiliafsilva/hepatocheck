import 'package:hive_ce_flutter/hive_ce_flutter.dart';

import '../../../core/crypto/encryption_key_provider.dart';
import '../../../domain/entities/drink_entry.dart';
import '../../../domain/entities/lab_exam.dart';
import '../../models/hive_registrar.g.dart';

abstract final class HiveDatabase {
  static const drinksBoxName = 'drinks';
  static const examsBoxName = 'exams';

  static Future<void> init(EncryptionKeyProvider keyProvider) async {
    await Hive.initFlutter();
    Hive.registerAdapters();

    final cipher = HiveAesCipher(await keyProvider.getOrCreateKey());
    await Hive.openBox<DrinkEntry>(drinksBoxName, encryptionCipher: cipher);
    await Hive.openBox<LabExam>(examsBoxName, encryptionCipher: cipher);
  }

  static Box<DrinkEntry> get drinks => Hive.box<DrinkEntry>(drinksBoxName);

  static Box<LabExam> get exams => Hive.box<LabExam>(examsBoxName);
}

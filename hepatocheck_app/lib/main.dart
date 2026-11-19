import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app.dart';
import 'core/crypto/encryption_key_provider.dart';
import 'data/datasources/local/hive_database.dart';
import 'data/sync/firestore_cloud_vault.dart';
import 'data/sync/hive_sync_queue_repository.dart';
import 'firebase_options.dart';
import 'presentation/providers/sync_providers.dart';
import 'presentation/widgets/auto_sync.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await HiveDatabase.init(EncryptionKeyProvider());
  await HiveSyncQueueRepository(HiveDatabase.syncQueue).recoverInterrupted();
  final vault = FirestoreCloudVault(FirebaseFirestore.instance);
  final uid = FirebaseAuth.instance.currentUser?.uid;
  if (uid != null) await vault.resume(uid);
  runApp(
    ProviderScope(
      overrides: [cloudVaultProvider.overrideWithValue(vault)],
      child: const AutoSync(child: MyApp()),
    ),
  );
}

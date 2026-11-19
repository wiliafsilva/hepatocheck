import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/auth/firebase_auth_repository.dart';
import '../../domain/entities/auth_user.dart';
import '../../domain/repositories/auth_repository.dart';
import 'consent_providers.dart';
import 'sync_providers.dart';

final authRepositoryProvider = Provider<AuthRepository>(
  (ref) => FirebaseAuthRepository(FirebaseAuth.instance),
);

final authStateProvider = StreamProvider<AuthUser?>(
  (ref) => ref.watch(authRepositoryProvider).authStateChanges(),
);

/// Encerra a sessão e revoga o consentimento: a autorização vale para a conta
/// que a deu, não para quem entrar depois neste aparelho.
Future<void> signOutAndRevokeConsent(WidgetRef ref) async {
  final uid = ref.read(authRepositoryProvider).currentUser?.uid;
  await ref.read(authRepositoryProvider).signOut();
  await ref.read(syncConsentControllerProvider.notifier).revoke();
  if (uid != null) await ref.read(cloudVaultProvider).forget(uid);
}

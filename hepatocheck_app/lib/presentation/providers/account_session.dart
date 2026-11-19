import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/sync/firestore_cloud_restore.dart';
import '../../domain/entities/drink_entry.dart';
import '../../domain/entities/lab_exam.dart';
import '../../domain/entities/reduction_goal.dart';
import '../../domain/repositories/cloud_restore.dart';
import '../../domain/repositories/cloud_vault.dart';
import 'auth_providers.dart';
import 'drink_providers.dart';
import 'exam_providers.dart';
import 'goal_providers.dart';
import 'sync_providers.dart';

final cloudRestoreProvider = Provider<CloudRestore>(
  (ref) => FirestoreCloudRestore(
    FirebaseFirestore.instance,
    ref.watch(cloudVaultProvider),
    drinks:
        ref.watch(drinkRepositoryProvider) as RestorableRepository<DrinkEntry>,
    exams: ref.watch(examRepositoryProvider) as RestorableRepository<LabExam>,
    goals: ref.watch(
      goalRepositoryProvider,
    ) as RestorableRepository<ReductionGoal>,
    queue: ref.watch(syncQueueRepositoryProvider),
  ),
);

class SignInResult {
  const SignInResult({this.report, this.keyReset = false});

  final RestoreReport? report;
  final bool keyReset;

  String? get message {
    if (keyReset) {
      return 'Como a senha foi recuperada, a cópia antiga da nuvem não pôde '
          'ser aberta. Os dados deste aparelho serão enviados de novo.';
    }
    final restored = report;
    if (restored == null) {
      return 'Não foi possível restaurar seus dados agora. Eles continuam '
          'guardados na nuvem; entre de novo mais tarde.';
    }
    if (restored.total == 0) return null;
    final parts = [
      if (restored.drinks > 0)
        '${restored.drinks} ${restored.drinks == 1 ? 'drinque' : 'drinques'}',
      if (restored.exams > 0)
        '${restored.exams} ${restored.exams == 1 ? 'exame' : 'exames'}',
      if (restored.goals > 0)
        '${restored.goals} ${restored.goals == 1 ? 'meta' : 'metas'}',
    ];
    final list = parts.length == 1
        ? parts.single
        : '${parts.sublist(0, parts.length - 1).join(', ')} e ${parts.last}';
    return 'Seus dados foram restaurados: $list.';
  }
}

final accountSessionProvider = Provider(AccountSession.new);

class AccountSession {
  AccountSession(this._ref);

  final Ref _ref;

  Future<SignInResult> signIn(String email, String password) async {
    final user = await _ref
        .read(authRepositoryProvider)
        .signIn(email: email, password: password);
    final vault = _ref.read(cloudVaultProvider);
    final restore = _ref.read(cloudRestoreProvider);
    var keyReset = false;
    try {
      try {
        await vault.unlock(user.uid, password);
      } on VaultKeyMismatchException {
        await vault.reset(user.uid, password);
        await restore.deleteRemote(user.uid);
        keyReset = true;
      }
      final report = await restore.restore(user.uid);
      _refresh();
      return SignInResult(report: report, keyReset: keyReset);
    } catch (_) {
      _refresh();
      return SignInResult(keyReset: keyReset);
    }
  }

  Future<void> register(String email, String password) async {
    final user = await _ref
        .read(authRepositoryProvider)
        .register(email: email, password: password);
    await _ref.read(cloudVaultProvider).create(user.uid, password);
  }

  void _refresh() {
    _ref
      ..invalidate(drinksProvider)
      ..invalidate(examsProvider)
      ..invalidate(goalsProvider)
      ..invalidate(syncStatusProvider);
  }
}

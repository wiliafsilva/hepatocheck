import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/auth_providers.dart';
import '../../providers/consent_providers.dart';
import '../../theme/app_text_styles.dart';
import '../../widgets/content_width.dart';
import '../sync_consent_screen.dart';
import 'change_password_screen.dart';
import 'login_screen.dart';

/// Abre o login (modo convidado) ou a tela da conta (autenticado).
void openAccount(BuildContext context, WidgetRef ref) {
  final signedIn = ref.read(authRepositoryProvider).currentUser != null;
  Navigator.of(context).push(
    MaterialPageRoute<void>(
      builder: (_) => signedIn ? const AccountScreen() : const LoginScreen(),
    ),
  );
}

/// Conta autenticada: e-mail, situação da sincronização e saída.
class AccountScreen extends ConsumerWidget {
  const AccountScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authStateProvider).value;
    final consent = ref.watch(syncConsentControllerProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Conta')),
      body: SafeArea(
        child: ContentWidth(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
            children: [
              const Text('Você está conectado', style: AppTextStyles.title),
              const SizedBox(height: 4),
              Text(
                user?.email ?? 'Conta sem e-mail',
                style: AppTextStyles.body,
              ),
              const SizedBox(height: 20),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.cloud_sync_outlined),
                title: const Text('Sincronização na nuvem'),
                subtitle: Text(
                  consent
                      ? 'Autorizada. Envio só com Wi-Fi.'
                      : 'Desligada. Nada é enviado.',
                ),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => const SyncConsentScreen(),
                  ),
                ),
              ),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.lock_reset_outlined),
                title: const Text('Alterar senha'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => const ChangePasswordScreen(),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              OutlinedButton.icon(
                onPressed: () async {
                  final navigator = Navigator.of(context);
                  await signOutAndRevokeConsent(ref);
                  navigator.popUntil((route) => route.isFirst);
                },
                icon: const Icon(Icons.logout),
                label: const Text('Sair da conta'),
              ),
              const SizedBox(height: 8),
              const Text(
                'Ao sair, a autorização de sincronização é desligada. Seus '
                'dados continuam neste aparelho.',
                style: AppTextStyles.caption,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/auth_providers.dart';
import '../providers/consent_providers.dart';
import '../screens/auth/account_screen.dart';
import '../screens/sync_consent_screen.dart';

/// Itens de conta e consentimento da aba Perfil.
class AccountSection extends ConsumerWidget {
  const AccountSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authStateProvider).value;
    final consent = ref.watch(syncConsentControllerProvider);

    return Column(
      children: [
        ListTile(
          contentPadding: EdgeInsets.zero,
          leading: const Icon(Icons.account_circle_outlined),
          title: Text(user == null ? 'Entrar ou criar conta' : 'Conta'),
          subtitle: Text(
            user == null
                ? 'Modo convidado: seus dados ficam só neste aparelho.'
                : user.email ?? 'Conectado',
          ),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => openAccount(context, ref),
        ),
        if (user != null)
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.privacy_tip_outlined),
            title: const Text('Consentimento de sincronização'),
            subtitle: Text(consent ? 'Autorizado' : 'Não autorizado'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => const SyncConsentScreen(),
              ),
            ),
          ),
      ],
    );
  }
}

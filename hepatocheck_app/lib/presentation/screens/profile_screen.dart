import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/auth_providers.dart';
import '../providers/consent_providers.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../widgets/delete_account_tile.dart';
import '../widgets/erase_local_data_tile.dart';
import '../widgets/export_summary_card.dart';
import '../widgets/section_label.dart';
import '../widgets/sign_out_dialog.dart';
import 'auth/account_screen.dart';
import 'auth/change_password_screen.dart';
import 'auth/privacy_policy_screen.dart';
import 'follow_up_screen.dart';
import 'goals_screen.dart';
import 'sync_consent_screen.dart';
import 'sync_status_screen.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({
    super.key,
    required this.camouflageEnabled,
    required this.onEnableCamouflage,
    required this.onDisableCamouflage,
  });

  final bool camouflageEnabled;
  final Future<void> Function(String code) onEnableCamouflage;
  final Future<void> Function() onDisableCamouflage;

  Future<void> _configureCamouflage(BuildContext context) async {
    final controller = TextEditingController();
    String? error;

    final code = await showDialog<String>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Criar código secreto'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Use um código numérico de 4 a 8 dígitos para voltar ao diário. Ele funciona mesmo após uma conta; basta digitá-lo na calculadora.',
              ),
              const SizedBox(height: 16),
              TextField(
                controller: controller,
                autofocus: true,
                keyboardType: TextInputType.number,
                obscureText: true,
                maxLength: 8,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: InputDecoration(
                  labelText: 'Código secreto',
                  errorText: error,
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () {
                if (controller.text.length < 4) {
                  setDialogState(() => error = 'Use pelo menos 4 dígitos.');
                  return;
                }
                Navigator.pop(dialogContext, controller.text);
              },
              child: const Text('Ativar'),
            ),
          ],
        ),
      ),
    );
    controller.dispose();

    if (code != null) await onEnableCamouflage(code);
  }

  void _open(BuildContext context, Widget screen) =>
      Navigator.of(context)
          .push(MaterialPageRoute<void>(builder: (_) => screen));

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authStateProvider).value;
    final consent = ref.watch(syncConsentControllerProvider);

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
      children: [
        _Group(
          children: [
            ListTile(
              leading: const CircleAvatar(
                backgroundColor: AppColors.surfaceVariant,
                foregroundColor: AppColors.olive,
                child: Icon(Icons.person_outline),
              ),
              title: Text(
                user == null
                    ? 'Modo convidado'
                    : user.email ?? 'Conta conectada',
              ),
              subtitle: Text(
                user == null
                    ? 'Entre com sua conta'
                    : 'Conta conectada',
              ),
              trailing: user == null ? const Icon(Icons.chevron_right) : null,
              onTap: user == null ? () => openAccount(context, ref) : null,
            ),
          ],
        ),
        const SizedBox(height: 20),
        const SectionLabel('PRIVACIDADE E SINCRONIZAÇÃO'),
        const SizedBox(height: 8),
        _Group(
          children: [
            if (user != null)
              ListTile(
                leading: const Icon(Icons.privacy_tip_outlined),
                title: const Text('Sincronização na nuvem'),
                subtitle: Text(consent ? 'Autorizada' : 'Desligada'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => _open(context, const SyncConsentScreen()),
              ),
            ListTile(
              leading: const Icon(Icons.cloud_sync_outlined),
              title: const Text('Status do envio'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => _open(context, const SyncStatusScreen()),
            ),
            SwitchListTile.adaptive(
              secondary: const Icon(Icons.calculate_outlined),
              title: const Text('Modo camuflagem'),
              value: camouflageEnabled,
              onChanged: (enabled) async {
                if (enabled) {
                  await _configureCamouflage(context);
                } else {
                  await onDisableCamouflage();
                }
              },
            ),
            ListTile(
              leading: const Icon(Icons.policy_outlined),
              title: const Text('Política de privacidade'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => _open(context, const PrivacyPolicyScreen()),
            ),
          ],
        ),
        const SizedBox(height: 20),
        const SectionLabel('ACOMPANHAMENTO'),
        const SizedBox(height: 8),
        _Group(
          children: [
            ListTile(
              leading: const Icon(Icons.flag_outlined),
              title: const Text('Metas de redução'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => _open(context, const GoalsScreen()),
            ),
            ListTile(
              leading: const Icon(Icons.notifications_outlined),
              title: const Text('Notificações e lembretes'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => _open(context, const FollowUpScreen()),
            ),
          ],
        ),
        const SizedBox(height: 20),
        const SectionLabel('RELATÓRIO'),
        const SizedBox(height: 8),
        _Group(
          children: [
            ListTile(
              leading: const Icon(Icons.picture_as_pdf_outlined),
              title: const Text('Exportar resumo em PDF'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => _open(context, const ExportSummaryScreen()),
            ),
          ],
        ),
        if (user != null) ...[
          const SizedBox(height: 20),
          const SectionLabel('CONTA'),
          const SizedBox(height: 8),
          _Group(
            children: [
              ListTile(
                leading: const Icon(Icons.lock_reset_outlined),
                title: const Text('Alterar senha'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => _open(context, const ChangePasswordScreen()),
              ),
              ListTile(
                leading: const Icon(Icons.logout, color: AppColors.riskRed),
                title: const Text(
                  'Sair da conta',
                  style: TextStyle(color: AppColors.riskRed),
                ),
                onTap: () async {
                  if (await confirmSignOut(context)) {
                    await signOutAndRevokeConsent(ref);
                  }
                },
              ),
              const DeleteAccountTile(),
            ],
          ),
        ],
        const SizedBox(height: 20),
        const _Group(
          children: [
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: EraseLocalDataTile(),
            ),
          ],
        ),
      ],
    );
  }
}

class ExportSummaryScreen extends StatelessWidget {
  const ExportSummaryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Resumo em PDF')),
      body: const SafeArea(
        child: Padding(
          padding: EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              ExportSummaryCard(),
              SizedBox(height: 12),
              Text(
                'O consumo do PDF segue o período escolhido no Relatório.',
                style: AppTextStyles.caption,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Group extends StatelessWidget {
  const _Group({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          for (final (index, child) in children.indexed) ...[
            if (index > 0) const Divider(height: 1, indent: 16, endIndent: 16),
            child,
          ],
        ],
      ),
    );
  }
}

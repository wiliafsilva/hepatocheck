import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/consent_providers.dart';
import '../providers/sync_providers.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../widgets/content_width.dart';
import 'auth/privacy_policy_screen.dart';

/// Consentimento para a sincronização com a nuvem (RF11, LGPD). Mostra o que
/// é enviado e o que nunca sai do aparelho, e permite autorizar ou revogar.
class SyncConsentScreen extends ConsumerWidget {
  const SyncConsentScreen({super.key});

  static const sent = [
    'Registros do diário, exames e metas',
    'Uma parte legível só com a data (sem o horário) e a faixa etária '
        '(ex.: 40-49)',
    'Os valores exatos, criptografados com a sua senha',
  ];
  static const neverSent = [
    'Seu nome, seu e-mail e sua senha',
    'Observações livres',
    'Código secreto da camuflagem',
    'Registro de alterações do diário',
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final granted = ref.watch(syncConsentControllerProvider);
    final controller = ref.read(syncConsentControllerProvider.notifier);

    return Scaffold(
      appBar: AppBar(title: const Text('Sincronização na nuvem')),
      body: SafeArea(
        child: ContentWidth(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
            children: [
              Text(
                granted
                    ? 'Você autorizou a sincronização.'
                    : 'Quer guardar uma cópia na nuvem?',
                style: AppTextStyles.title,
              ),
              const SizedBox(height: 8),
              const Text(
                'Seus dados continuam guardados neste aparelho. Com a sua '
                'autorização, uma cópia criptografada com a sua senha é '
                'enviada quando houver Wi-Fi. Ao entrar na sua conta em outro '
                'aparelho, seus dados voltam sozinhos. Sem autorização, nada '
                'é enviado.',
                style: AppTextStyles.body,
              ),
              const SizedBox(height: 20),
              const _Checklist(
                title: 'O que é enviado',
                items: sent,
                icon: Icons.check_circle_outline,
                color: AppColors.olive,
              ),
              const SizedBox(height: 16),
              const _Checklist(
                title: 'O que nunca é enviado',
                items: neverSent,
                icon: Icons.block,
                color: AppColors.riskRed,
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => const PrivacyPolicyScreen(),
                  ),
                ),
                child: const Text('Ler a política de privacidade'),
              ),
              const SizedBox(height: 12),
              if (!granted) ...[
                FilledButton(
                  onPressed: () async {
                    await controller.grant();
                    ref.read(syncStatusProvider.notifier).refresh();
                    if (context.mounted) Navigator.of(context).maybePop();
                  },
                  child: const Text('Autorizar sincronização'),
                ),
                const SizedBox(height: 8),
                OutlinedButton(
                  onPressed: () => Navigator.of(context).maybePop(),
                  child: const Text('Agora não'),
                ),
              ] else ...[
                const Text(
                  'Você pode revogar quando quiser. Os dados já enviados '
                  'continuam na nuvem; novos registros deixam de ser '
                  'enviados.',
                  style: AppTextStyles.caption,
                ),
                const SizedBox(height: 12),
                OutlinedButton(
                  onPressed: () async {
                    await controller.revoke();
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'Sincronização desligada. Nada mais será enviado.',
                          ),
                        ),
                      );
                    }
                  },
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.riskRed,
                  ),
                  child: const Text('Revogar autorização'),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _Checklist extends StatelessWidget {
  const _Checklist({
    required this.title,
    required this.items,
    required this.icon,
    required this.color,
  });

  final String title;
  final List<String> items;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: AppTextStyles.subtitle),
            const SizedBox(height: 8),
            for (final item in items)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(icon, size: 18, color: color),
                    const SizedBox(width: 10),
                    Expanded(child: Text(item, style: AppTextStyles.body)),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/auth_providers.dart';
import '../providers/local_data_providers.dart';
import '../theme/app_colors.dart';

class EraseLocalDataTile extends ConsumerWidget {
  const EraseLocalDataTile({super.key});

  static const offlineMessage =
      'Conecte-se à internet para apagar também a cópia da nuvem. '
      'Nada foi apagado.';

  Future<void> _confirmAndErase(BuildContext context, WidgetRef ref) async {
    final signedIn = ref.read(authRepositoryProvider).currentUser != null;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Apagar todos os dados?'),
        content: Text(
          signedIn
              ? 'Isso apaga deste aparelho e da nuvem todos os drinques, exames, metas e registros que aguardam envio, e desliga os lembretes. Não é possível desfazer. Sua conta continua existindo.'
              : 'Isso apaga deste aparelho todos os drinques, exames, metas e registros que aguardam envio, e desliga os lembretes. Não é possível desfazer.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.riskRed),
            child: const Text('Apagar tudo'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    final erased = await eraseAllData(ref);
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          !erased
              ? offlineMessage
              : signedIn
              ? 'Todos os dados deste aparelho e da nuvem foram apagados.'
              : 'Todos os dados deste aparelho foram apagados.',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: const Icon(
        Icons.delete_forever_outlined,
        color: AppColors.riskRed,
      ),
      title: const Text(
        'Apagar todos os dados',
        style: TextStyle(color: AppColors.riskRed),
      ),
      onTap: () => _confirmAndErase(context, ref),
    );
  }
}

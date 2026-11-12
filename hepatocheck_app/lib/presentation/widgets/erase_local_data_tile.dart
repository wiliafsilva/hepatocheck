import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/local_data_providers.dart';
import '../theme/app_colors.dart';

class EraseLocalDataTile extends ConsumerWidget {
  const EraseLocalDataTile({super.key});

  Future<void> _confirmAndErase(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Apagar todos os dados?'),
        content: const Text(
          'Isso apaga deste aparelho todos os drinques, exames e registros que aguardam envio. Não é possível desfazer. Dados que já foram sincronizados com a nuvem não são apagados.',
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

    await eraseAllLocalData(ref);
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Todos os dados deste aparelho foram apagados.'),
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
      title: const Text('Apagar todos os dados'),
      subtitle: const Text('Remove drinques e exames deste aparelho'),
      onTap: () => _confirmAndErase(context, ref),
    );
  }
}

import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

Future<bool> confirmSignOut(BuildContext context) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: const Text('Sair da conta?'),
      content: const Text(
        'Ao sair, a sincronização com a nuvem é desligada e a chave da cópia '
        'criptografada é esquecida neste aparelho. Seus registros continuam '
        'guardados aqui. Para voltar a sincronizar, entre de novo com a sua '
        'senha.',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(dialogContext, false),
          child: const Text('Cancelar'),
        ),
        TextButton(
          onPressed: () => Navigator.pop(dialogContext, true),
          style: TextButton.styleFrom(foregroundColor: AppColors.riskRed),
          child: const Text('Sair'),
        ),
      ],
    ),
  );
  return confirmed ?? false;
}

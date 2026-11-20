import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/account_session.dart';
import '../theme/app_colors.dart';

class DeleteAccountTile extends ConsumerWidget {
  const DeleteAccountTile({super.key});

  static String messageFor(DeleteAccountResult result) => switch (result) {
    DeleteAccountResult.deleted =>
      'Sua conta e todos os seus dados foram apagados.',
    DeleteAccountResult.wrongPassword =>
      'A senha está incorreta. Nada foi apagado.',
    DeleteAccountResult.offline =>
      'Conecte-se à internet para apagar a conta. Nada foi apagado.',
    DeleteAccountResult.accountKept =>
      'Os dados da nuvem e do aparelho foram apagados, mas não foi possível '
          'apagar a conta. Tente de novo.',
  };

  Future<void> _confirmAndDelete(BuildContext context, WidgetRef ref) async {
    final password = await showDialog<String>(
      context: context,
      builder: (_) => const _DeleteAccountDialog(),
    );
    if (password == null || !context.mounted) return;

    final messenger = ScaffoldMessenger.of(context);
    final result = await ref
        .read(accountSessionProvider)
        .deleteAccount(password);
    messenger.showSnackBar(SnackBar(content: Text(messageFor(result))));
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ListTile(
      leading: const Icon(
        Icons.person_remove_outlined,
        color: AppColors.riskRed,
      ),
      title: const Text(
        'Apagar a conta',
        style: TextStyle(color: AppColors.riskRed),
      ),
      onTap: () => _confirmAndDelete(context, ref),
    );
  }
}

class _DeleteAccountDialog extends StatefulWidget {
  const _DeleteAccountDialog();

  @override
  State<_DeleteAccountDialog> createState() => _DeleteAccountDialogState();
}

class _DeleteAccountDialogState extends State<_DeleteAccountDialog> {
  final _password = TextEditingController();
  String? _error;

  @override
  void dispose() {
    _password.dispose();
    super.dispose();
  }

  void _confirm() {
    if (_password.text.isEmpty) {
      setState(() => _error = 'Digite a sua senha para confirmar.');
      return;
    }
    Navigator.pop(context, _password.text);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Apagar a conta?'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Isso apaga a sua conta, a cópia criptografada da nuvem e todos '
              'os drinques, exames e metas deste aparelho. O app volta a '
              'funcionar em modo convidado, vazio. Não é possível desfazer.',
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _password,
              obscureText: true,
              autofocus: true,
              decoration: InputDecoration(
                labelText: 'Senha',
                errorText: _error,
              ),
              onSubmitted: (_) => _confirm(),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        TextButton(
          onPressed: _confirm,
          style: TextButton.styleFrom(foregroundColor: AppColors.riskRed),
          child: const Text('Apagar conta'),
        ),
      ],
    );
  }
}

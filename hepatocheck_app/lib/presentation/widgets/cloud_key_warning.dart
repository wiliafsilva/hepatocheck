import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';

Future<bool> showCloudKeyWarning(BuildContext context) async {
  final accepted = await showDialog<bool>(
    context: context,
    builder: (_) => const CloudKeyWarning(),
  );
  return accepted ?? false;
}

class CloudKeyWarning extends StatefulWidget {
  const CloudKeyWarning({super.key});

  static const title = 'Seus dados ficam trancados com a sua senha';

  @override
  State<CloudKeyWarning> createState() => _CloudKeyWarningState();
}

class _CloudKeyWarningState extends State<CloudKeyWarning> {
  bool _understood = false;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      icon: const Icon(Icons.lock_outline, color: AppColors.olive),
      title: const Text(CloudKeyWarning.title),
      scrollable: true,
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'A cópia dos seus dados na nuvem é criptografada com a sua senha. '
            'Nem a equipe do HepatoCheck consegue lê-la.',
            style: AppTextStyles.body,
          ),
          const SizedBox(height: 12),
          const Text(
            'Se você esquecer a senha, poderá criar uma nova, mas a cópia '
            'antiga da nuvem não poderá ser aberta. Os dados que estiverem '
            'neste aparelho continuam e são enviados de novo.',
            style: AppTextStyles.body,
          ),
          const SizedBox(height: 12),
          Text(
            'Se você perder a senha e este aparelho, o histórico não poderá '
            'ser recuperado.',
            style: AppTextStyles.body.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          CheckboxListTile(
            contentPadding: EdgeInsets.zero,
            controlAffinity: ListTileControlAffinity.leading,
            value: _understood,
            onChanged: (value) => setState(() => _understood = value ?? false),
            title: const Text('Entendi'),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed: _understood ? () => Navigator.pop(context, true) : null,
          child: const Text('Continuar'),
        ),
      ],
    );
  }
}

import 'package:flutter/material.dart';

import '../../theme/app_text_styles.dart';
import '../../widgets/content_width.dart';

/// Política de privacidade resumida, em linguagem simples (LGPD).
class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  static const sections = <(String, String)>[
    (
      'Seus dados ficam com você',
      'Exames, diário de consumo e metas são guardados criptografados neste '
          'aparelho. Sem conta e sem autorização, nada sai daqui.',
    ),
    (
      'Quando enviamos algo',
      'Só se você criar uma conta, autorizar a sincronização e estiver '
          'conectado ao Wi-Fi. Você pode revogar a autorização quando quiser.',
    ),
    (
      'O que é enviado',
      'Os registros do diário, os exames e as metas, já anonimizados: sem '
          'nome, sem e-mail, sem horário exato (só a data), com a idade '
          'trocada por uma faixa etária e sem observações livres.',
    ),
    (
      'O que nunca é enviado',
      'Seu nome, seu e-mail, o código secreto da camuflagem e o registro de '
          'alterações do diário.',
    ),
    (
      'Seus direitos',
      'Você pode apagar todos os dados do aparelho no Perfil e revogar o '
          'consentimento a qualquer momento. O aplicativo é um indicador '
          'educativo e não substitui avaliação médica.',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Política de privacidade')),
      body: SafeArea(
        child: ContentWidth(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
            children: [
              for (final (title, text) in sections) ...[
                Text(title, style: AppTextStyles.subtitle),
                const SizedBox(height: 4),
                Text(text, style: AppTextStyles.body),
                const SizedBox(height: 20),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

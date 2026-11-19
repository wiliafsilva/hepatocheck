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
      'Os registros do diário, os exames e as metas, em duas partes. A parte '
          'legível é anonimizada: sem nome, sem e-mail, sem horário exato (só '
          'a data), com a idade trocada por uma faixa etária e sem '
          'observações livres. Os valores exatos vão criptografados com a '
          'sua senha: nem a equipe do HepatoCheck consegue lê-los.',
    ),
    (
      'Seus dados em outro aparelho',
      'Ao entrar na sua conta em outro aparelho ou depois de reinstalar o '
          'aplicativo, seus dados voltam sozinhos, abertos com a sua senha.',
    ),
    (
      'Se você esquecer a senha',
      'Você pode criar uma nova, mas a cópia antiga da nuvem não poderá ser '
          'aberta. Os dados que estiverem no aparelho continuam e são '
          'enviados de novo. Se você perder a senha e o aparelho, o histórico '
          'não poderá ser recuperado.',
    ),
    (
      'O que nunca é enviado',
      'Seu nome, seu e-mail, sua senha, o código secreto da camuflagem e o '
          'registro de alterações do diário.',
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

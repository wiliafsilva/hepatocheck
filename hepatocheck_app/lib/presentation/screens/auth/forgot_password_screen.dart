import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/auth_providers.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../../widgets/cloud_key_warning.dart';
import '../../widgets/content_width.dart';
import 'auth_flow.dart';
import 'auth_validators.dart';
import 'auth_widgets.dart';

/// Recuperação de senha: o Firebase envia por e-mail o link para criar uma
/// nova senha. A resposta é a mesma exista ou não conta com o e-mail.
class ForgotPasswordScreen extends ConsumerStatefulWidget {
  const ForgotPasswordScreen({
    super.key,
    this.initialEmail = '',
    this.backPrompt = 'Lembrou a senha? ',
    this.backAction = 'Voltar ao login',
  });

  final String initialEmail;
  final String backPrompt;
  final String backAction;

  @override
  ConsumerState<ForgotPasswordScreen> createState() =>
      _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends ConsumerState<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  late final _email = TextEditingController(text: widget.initialEmail);
  bool _busy = false;
  bool _sent = false;
  String? _error;

  @override
  void dispose() {
    _email.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_busy) return;
    if (!_formKey.currentState!.validate()) return;
    if (!await showCloudKeyWarning(context)) return;
    if (!mounted) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    final error = await runAuth(
      () => ref
          .read(authRepositoryProvider)
          .sendPasswordReset(_email.text.trim()),
    );
    if (!mounted) return;
    setState(() {
      _busy = false;
      _error = error;
      _sent = error == null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      body: SafeArea(
        child: ContentWidth(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
            children: [
              const Text('Esqueceu sua senha?', style: AppTextStyles.title),
              const SizedBox(height: 4),
              Text(
                'Informe o e-mail da sua conta. Enviaremos um link para você '
                'criar uma nova senha.',
                style: AppTextStyles.body.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 24),
              Form(
                key: _formKey,
                child: AuthTextField(
                  label: 'E-mail',
                  hint: 'seuemail@exemplo.com',
                  controller: _email,
                  keyboardType: TextInputType.emailAddress,
                  autofillHints: const [AutofillHints.email],
                  textInputAction: TextInputAction.done,
                  onFieldSubmitted: (_) => _submit(),
                  validator: AuthValidators.email,
                ),
              ),
              if (_sent) ...[
                const SizedBox(height: 12),
                Text(
                  'Se houver uma conta com esse e-mail, o link já foi '
                  'enviado. Confira também a caixa de spam.',
                  style: AppTextStyles.body.copyWith(color: AppColors.olive),
                ),
              ],
              if (_error != null) AuthErrorText(_error!),
              const SizedBox(height: 24),
              AuthSubmitButton(
                label: _sent ? 'Enviar de novo' : 'Enviar link de recuperação',
                busy: _busy,
                onPressed: _submit,
              ),
              const SizedBox(height: 24),
              AuthPromptLink(
                prompt: widget.backPrompt,
                action: widget.backAction,
                onPressed: () => Navigator.of(context).maybePop(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

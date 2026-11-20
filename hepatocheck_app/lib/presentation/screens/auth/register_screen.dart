import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/account_session.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../../widgets/cloud_key_warning.dart';
import '../../widgets/content_width.dart';
import 'auth_flow.dart';
import 'auth_validators.dart';
import 'auth_widgets.dart';
import 'privacy_policy_screen.dart';

/// Tela de cadastro com e-mail e senha. Nome não é pedido: dados pessoais
/// não são necessários e nunca vão para o Firestore.
class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key, this.onSubmit});

  /// Substitui o cadastro real (usado nos testes).
  final AuthSubmit? onSubmit;

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _confirm = TextEditingController();
  late final _policyLink = TapGestureRecognizer()..onTap = _openPolicy;
  bool _obscure = true;
  bool _accepted = false;
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    _confirm.dispose();
    _policyLink.dispose();
    super.dispose();
  }

  void _openPolicy() => Navigator.of(
    context,
  ).push(MaterialPageRoute<void>(builder: (_) => const PrivacyPolicyScreen()));

  Future<void> _submit() async {
    if (_busy || !_accepted) return;
    if (!_formKey.currentState!.validate()) return;
    if (!await showCloudKeyWarning(context)) return;
    if (!mounted) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    final email = _email.text.trim();
    final password = _password.text;
    final error = await runAuth(() async {
      final custom = widget.onSubmit;
      if (custom != null) return custom(email, password);
      await ref.read(accountSessionProvider).register(email, password);
    });
    if (!mounted) return;
    if (error != null) {
      setState(() {
        _busy = false;
        _error = error;
      });
      return;
    }
    finishAuthFlow(context, ref);
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
              const Text('Criar Conta', style: AppTextStyles.title),
              const SizedBox(height: 4),
              Text(
                'Leva menos de um minuto. Você pode sincronizar depois.',
                style: AppTextStyles.body.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 24),
              Form(
                key: _formKey,
                child: Column(
                  children: [
                    AuthTextField(
                      label: 'E-mail',
                      hint: 'seuemail@exemplo.com',
                      controller: _email,
                      keyboardType: TextInputType.emailAddress,
                      autofillHints: const [AutofillHints.email],
                      textInputAction: TextInputAction.next,
                      validator: AuthValidators.email,
                    ),
                    const SizedBox(height: 16),
                    AuthTextField(
                      label: 'Senha',
                      hint:
                          'Mínimo ${AuthValidators.minPasswordLength} caracteres',
                      controller: _password,
                      obscureText: _obscure,
                      autofillHints: const [AutofillHints.newPassword],
                      textInputAction: TextInputAction.next,
                      suffixIcon: PasswordVisibilityButton(
                        obscured: _obscure,
                        onPressed: () => setState(() => _obscure = !_obscure),
                      ),
                      validator: AuthValidators.password,
                    ),
                    const SizedBox(height: 16),
                    AuthTextField(
                      label: 'Confirmar senha',
                      hint: 'Repita sua senha',
                      controller: _confirm,
                      obscureText: _obscure,
                      textInputAction: TextInputAction.done,
                      onFieldSubmitted: (_) => _submit(),
                      validator: (v) =>
                          AuthValidators.confirmPassword(v, _password.text),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              _buildAcceptance(),
              if (_error != null) AuthErrorText(_error!),
              const SizedBox(height: 20),
              AuthSubmitButton(
                label: 'Criar conta',
                busy: _busy,
                onPressed: _accepted ? _submit : null,
              ),
              if (!_accepted) ...[
                const SizedBox(height: 8),
                const Text(
                  'Aceite a política de privacidade para continuar',
                  textAlign: TextAlign.center,
                  style: AppTextStyles.caption,
                ),
              ],
              const SizedBox(height: 24),
              Text(
                'Prefere não se cadastrar agora?',
                textAlign: TextAlign.center,
                style: AppTextStyles.body.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              Center(
                child: TextButton(
                  onPressed: () =>
                      Navigator.of(context).popUntil((route) => route.isFirst),
                  child: Text(
                    'Continuar como Convidado',
                    style: AppTextStyles.label.copyWith(color: AppColors.olive),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              AuthPromptLink(
                prompt: 'Já tem conta? ',
                action: 'Entrar',
                onPressed: () => Navigator.of(context).maybePop(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAcceptance() {
    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => setState(() => _accepted = !_accepted),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(4, 8, 12, 8),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Checkbox(
                value: _accepted,
                onChanged: (value) =>
                    setState(() => _accepted = value ?? false),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: Text.rich(
                    TextSpan(
                      style: AppTextStyles.caption,
                      children: [
                        const TextSpan(text: 'Li e aceito a '),
                        TextSpan(
                          text: 'Política de Privacidade',
                          recognizer: _policyLink,
                          style: const TextStyle(
                            color: AppColors.olive,
                            decoration: TextDecoration.underline,
                            decorationColor: AppColors.olive,
                          ),
                        ),
                        const TextSpan(
                          text:
                              '. Sei que meu diário de álcool só é '
                              'sincronizado se eu autorizar.',
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

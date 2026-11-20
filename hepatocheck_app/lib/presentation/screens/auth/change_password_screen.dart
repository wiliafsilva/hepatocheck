import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../domain/repositories/auth_repository.dart';
import '../../providers/account_session.dart';
import '../../providers/auth_providers.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../../widgets/content_width.dart';
import '../../widgets/section_label.dart';
import 'auth_flow.dart';
import 'auth_validators.dart';
import 'auth_widgets.dart';
import 'forgot_password_screen.dart';

typedef ChangePasswordSubmit = Future<void> Function(
  String currentPassword,
  String newPassword,
);

class ChangePasswordScreen extends ConsumerStatefulWidget {
  const ChangePasswordScreen({super.key, this.onSubmit});

  final ChangePasswordSubmit? onSubmit;

  @override
  ConsumerState<ChangePasswordScreen> createState() =>
      _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends ConsumerState<ChangePasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _current = TextEditingController();
  final _new = TextEditingController();
  final _confirm = TextEditingController();
  bool _obscure = true;
  bool _busy = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _new.addListener(_onChanged);
    _confirm.addListener(_onChanged);
  }

  @override
  void dispose() {
    _current.dispose();
    _new.dispose();
    _confirm.dispose();
    super.dispose();
  }

  void _onChanged() => setState(() {});

  Future<void> _submit() async {
    if (_busy) return;
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    final current = _current.text;
    final next = _new.text;
    String? error;
    try {
      final custom = widget.onSubmit;
      if (custom != null) {
        await custom(current, next);
      } else {
        await ref.read(accountSessionProvider).changePassword(current, next);
      }
    } on AuthFailure catch (failure) {
      error = failure.code == AuthFailureCode.wrongCredentials
          ? 'A senha atual está incorreta.'
          : authFailureMessage(failure.code);
    } catch (_) {
      error = authFailureMessage(AuthFailureCode.unknown);
    }
    if (!mounted) return;
    if (error != null) {
      setState(() {
        _busy = false;
        _error = error;
      });
      return;
    }
    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text('Senha alterada.')));
    Navigator.of(context).maybePop();
  }

  @override
  Widget build(BuildContext context) {
    final email = ref.watch(authStateProvider).value?.email ?? '';
    final longEnough = _new.text.length >= AuthValidators.minPasswordLength;
    final matches = _new.text.isNotEmpty && _new.text == _confirm.text;

    return Scaffold(
      appBar: AppBar(),
      body: SafeArea(
        child: ContentWidth(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
            children: [
              const Text('Alterar senha', style: AppTextStyles.title),
              const SizedBox(height: 4),
              Text(
                'Por segurança, confirme sua senha atual antes de definir '
                'uma nova.',
                style: AppTextStyles.body.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 24),
              Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    AuthTextField(
                      label: 'Senha atual',
                      controller: _current,
                      obscureText: _obscure,
                      autofillHints: const [AutofillHints.password],
                      textInputAction: TextInputAction.next,
                      suffixIcon: PasswordVisibilityButton(
                        obscured: _obscure,
                        onPressed: () => setState(() => _obscure = !_obscure),
                      ),
                      validator: AuthValidators.password,
                    ),
                    Align(
                      alignment: Alignment.centerRight,
                      child: AuthLink(
                        text: 'Não lembro minha senha atual',
                        onPressed: () => Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (_) => ForgotPasswordScreen(
                              initialEmail: email,
                              backPrompt: 'Lembrou a senha? ',
                              backAction: 'Voltar',
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    AuthTextField(
                      label: 'Nova senha',
                      controller: _new,
                      obscureText: _obscure,
                      autofillHints: const [AutofillHints.newPassword],
                      textInputAction: TextInputAction.next,
                      validator: AuthValidators.password,
                    ),
                    const SizedBox(height: 16),
                    AuthTextField(
                      label: 'Confirmar senha',
                      controller: _confirm,
                      obscureText: _obscure,
                      textInputAction: TextInputAction.done,
                      onFieldSubmitted: (_) => _submit(),
                      validator: (v) =>
                          AuthValidators.confirmPassword(v, _new.text),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              const SectionLabel('A NOVA SENHA PRECISA TER'),
              const SizedBox(height: 8),
              Card(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  child: Column(
                    children: [
                      _Rule(
                        text:
                            'Pelo menos ${AuthValidators.minPasswordLength} '
                            'caracteres',
                        met: longEnough,
                      ),
                      _Rule(text: 'A mesma senha na confirmação', met: matches),
                    ],
                  ),
                ),
              ),
              if (_error != null) AuthErrorText(_error!),
              const SizedBox(height: 24),
              AuthSubmitButton(
                label: 'Salvar nova senha',
                busy: _busy,
                onPressed: _submit,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Rule extends StatelessWidget {
  const _Rule({required this.text, required this.met});

  final String text;
  final bool met;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: '$text: ${met ? 'cumprido' : 'pendente'}',
      excludeSemantics: true,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            Icon(
              met ? Icons.check_circle_outline : Icons.radio_button_unchecked,
              color: AppColors.olive,
              size: 20,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                text,
                style: AppTextStyles.body.copyWith(
                  color: met ? AppColors.textPrimary : AppColors.textSecondary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

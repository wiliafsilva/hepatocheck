import 'package:flutter/material.dart';

import '../../theme/app_text_styles.dart';
import 'auth_validators.dart';
import 'login_screen.dart' show AuthSubmit;
import '../../widgets/content_width.dart';

/// Tela de cadastro com e-mail e senha. Nome não é pedido: dados pessoais
/// não são necessários e nunca vão para o Firestore.
class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key, this.onSubmit});

  final AuthSubmit? onSubmit;

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _confirm = TextEditingController();
  bool _obscure = true;
  bool _busy = false;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    _confirm.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final onSubmit = widget.onSubmit;
    if (onSubmit == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Cadastro de conta ainda não está disponível.'),
        ),
      );
      return;
    }
    setState(() => _busy = true);
    try {
      await onSubmit(_email.text.trim(), _password.text);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
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
              const Text('Criar conta', style: AppTextStyles.title),
              const SizedBox(height: 4),
              const Text(
                'Use e-mail e senha. Seus registros continuam guardados no '
                'aparelho e só são enviados com a sua autorização.',
                style: AppTextStyles.body,
              ),
              const SizedBox(height: 24),
              Form(
                key: _formKey,
                child: Column(
                  children: [
                    TextFormField(
                      controller: _email,
                      keyboardType: TextInputType.emailAddress,
                      autofillHints: const [AutofillHints.email],
                      textInputAction: TextInputAction.next,
                      decoration: const InputDecoration(labelText: 'E-mail'),
                      validator: AuthValidators.email,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _password,
                      obscureText: _obscure,
                      autofillHints: const [AutofillHints.newPassword],
                      textInputAction: TextInputAction.next,
                      decoration: InputDecoration(
                        labelText: 'Senha',
                        suffixIcon: IconButton(
                          tooltip: _obscure ? 'Mostrar senha' : 'Ocultar senha',
                          icon: Icon(
                            _obscure
                                ? Icons.visibility_outlined
                                : Icons.visibility_off_outlined,
                          ),
                          onPressed: () => setState(() => _obscure = !_obscure),
                        ),
                      ),
                      validator: AuthValidators.password,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _confirm,
                      obscureText: _obscure,
                      textInputAction: TextInputAction.done,
                      onFieldSubmitted: (_) => _submit(),
                      decoration: const InputDecoration(
                        labelText: 'Confirmar senha',
                      ),
                      validator: (v) =>
                          AuthValidators.confirmPassword(v, _password.text),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              FilledButton(
                onPressed: _busy ? null : _submit,
                child: _busy
                    ? const SizedBox.square(
                        dimension: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Criar conta'),
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: () => Navigator.of(context).maybePop(),
                child: const Text('Já tenho conta'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

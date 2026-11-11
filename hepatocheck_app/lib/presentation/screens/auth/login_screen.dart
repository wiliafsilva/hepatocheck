import 'package:flutter/material.dart';

import '../../theme/app_text_styles.dart';
import 'auth_validators.dart';
import 'register_screen.dart';
import '../../widgets/content_width.dart';

/// Chamado com e-mail e senha já validados. Será ligado ao Firebase
/// Authentication na Sprint 3 (tarefa 37).
typedef AuthSubmit = Future<void> Function(String email, String password);

/// Tela de login. A conta é opcional: o modo convidado continua disponível
/// (RF08) e só a sincronização em nuvem exige autenticação.
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key, this.onSubmit});

  final AuthSubmit? onSubmit;

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _obscure = true;
  bool _busy = false;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final onSubmit = widget.onSubmit;
    if (onSubmit == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Login com conta ainda não está disponível.'),
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
              const Text('Entrar', style: AppTextStyles.title),
              const SizedBox(height: 4),
              const Text(
                'A conta é opcional e serve apenas para sincronizar seus '
                'dados com a nuvem.',
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
                      autofillHints: const [AutofillHints.password],
                      textInputAction: TextInputAction.done,
                      onFieldSubmitted: (_) => _submit(),
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
                    : const Text('Entrar'),
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => RegisterScreen(onSubmit: widget.onSubmit),
                  ),
                ),
                child: const Text('Criar conta'),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).maybePop(),
                child: const Text('Continuar como convidado'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

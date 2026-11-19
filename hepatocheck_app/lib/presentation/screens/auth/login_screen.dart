import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/account_session.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../../widgets/content_width.dart';
import 'auth_flow.dart';
import 'auth_validators.dart';
import 'auth_widgets.dart';
import 'forgot_password_screen.dart';
import 'register_screen.dart';

/// Tela de login. A conta é opcional: o modo convidado continua disponível
/// (RF08) e só a sincronização em nuvem exige autenticação.
class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key, this.onSubmit});

  /// Substitui o login real (usado nos testes).
  final AuthSubmit? onSubmit;

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _obscure = true;
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_busy) return;
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    final email = _email.text.trim();
    final password = _password.text;
    SignInResult? result;
    final error = await runAuth(() async {
      final custom = widget.onSubmit;
      if (custom != null) return custom(email, password);
      result = await ref.read(accountSessionProvider).signIn(email, password);
    });
    if (!mounted) return;
    if (error != null) {
      setState(() {
        _busy = false;
        _error = error;
      });
      return;
    }
    final message = result?.message;
    final messenger = ScaffoldMessenger.of(context);
    finishAuthFlow(context, ref);
    if (message != null) {
      messenger.showSnackBar(SnackBar(content: Text(message)));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      body: SafeArea(
        child: ContentWidth(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
            children: [
              const _LoginLogo(),
              const SizedBox(height: 16),
              Text(
                'Seu fígado, sob controle.',
                textAlign: TextAlign.center,
                style: AppTextStyles.subtitle.copyWith(
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Diário privado e risco FIB-4 num só lugar.',
                textAlign: TextAlign.center,
                style: AppTextStyles.body.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 28),
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
                      hint: 'Digite sua senha',
                      controller: _password,
                      obscureText: _obscure,
                      autofillHints: const [AutofillHints.password],
                      textInputAction: TextInputAction.done,
                      onFieldSubmitted: (_) => _submit(),
                      suffixIcon: PasswordVisibilityButton(
                        obscured: _obscure,
                        onPressed: () => setState(() => _obscure = !_obscure),
                      ),
                      validator: AuthValidators.password,
                    ),
                  ],
                ),
              ),
              Align(
                alignment: Alignment.centerRight,
                child: AuthLink(
                  text: 'Esqueci minha senha',
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => ForgotPasswordScreen(
                        initialEmail: _email.text.trim(),
                      ),
                    ),
                  ),
                ),
              ),
              if (_error != null) AuthErrorText(_error!),
              const SizedBox(height: 20),
              AuthSubmitButton(
                label: 'Entrar',
                busy: _busy,
                onPressed: _submit,
              ),
              const SizedBox(height: 20),
              const _OrDivider(),
              const SizedBox(height: 20),
              OutlinedButton(
                onPressed: () => Navigator.of(context).maybePop(),
                child: const Text('Continuar como convidado'),
              ),
              const SizedBox(height: 16),
              AuthPromptLink(
                prompt: 'Não tem conta? ',
                action: 'Criar conta',
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => RegisterScreen(onSubmit: widget.onSubmit),
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

class _OrDivider extends StatelessWidget {
  const _OrDivider();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Expanded(child: Divider(color: AppColors.outline)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            'Ou',
            style: AppTextStyles.label.copyWith(color: AppColors.olive),
          ),
        ),
        const Expanded(child: Divider(color: AppColors.outline)),
      ],
    );
  }
}

class _LoginLogo extends StatelessWidget {
  const _LoginLogo();

  @override
  Widget build(BuildContext context) {
    return const ExcludeSemantics(
      child: Center(
        child: SizedBox.square(
          dimension: 170,
          child: CustomPaint(painter: _LoginLogoPainter()),
        ),
      ),
    );
  }
}

class _LoginLogoPainter extends CustomPainter {
  const _LoginLogoPainter();

  static const _accent = Color(0xFFB4C96A);

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final scale = size.shortestSide / 230;

    canvas.drawCircle(
      center,
      115 * scale,
      Paint()
        ..shader = RadialGradient(
          colors: [
            AppColors.olive.withValues(alpha: 0.16),
            AppColors.olive.withValues(alpha: 0),
          ],
        ).createShader(Rect.fromCircle(center: center, radius: 115 * scale)),
    );

    final dashed = Paint()
      ..color = AppColors.olive.withValues(alpha: 0.35)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    const dashes = 72;
    for (var i = 0; i < dashes; i++) {
      final start = i * 2 * math.pi / dashes;
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: 105 * scale),
        start,
        math.pi / dashes,
        false,
        dashed,
      );
    }

    final ring = Paint()
      ..color = AppColors.olive.withValues(alpha: 0.35)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    canvas.drawCircle(center, 73 * scale, ring);
    canvas.drawCircle(center, 47 * scale, ring);

    canvas.drawCircle(
      center,
      36 * scale,
      Paint()..color = AppColors.olive.withValues(alpha: 0.12),
    );
    canvas.drawCircle(
      center,
      36 * scale,
      Paint()
        ..color = _accent
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2 * scale,
    );

    final pulse = Path()
      ..moveTo(center.dx - 17 * scale, center.dy)
      ..lineTo(center.dx - 6 * scale, center.dy)
      ..lineTo(center.dx - 3 * scale, center.dy - 10 * scale)
      ..lineTo(center.dx + 2 * scale, center.dy + 10 * scale)
      ..lineTo(center.dx + 5 * scale, center.dy)
      ..lineTo(center.dx + 16 * scale, center.dy);
    canvas.drawPath(
      pulse,
      Paint()
        ..color = _accent
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2 * scale
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );

    void dot(double angle, double radius) {
      final position =
          center + Offset(math.cos(angle), math.sin(angle)) * (radius * scale);
      canvas.drawCircle(
        position,
        9 * scale,
        Paint()..color = _accent.withValues(alpha: 0.25),
      );
      canvas.drawCircle(position, 5 * scale, Paint()..color = _accent);
    }

    dot(-0.67, 105);
    dot(2.6, 73);
  }

  @override
  bool shouldRepaint(_LoginLogoPainter oldDelegate) => false;
}

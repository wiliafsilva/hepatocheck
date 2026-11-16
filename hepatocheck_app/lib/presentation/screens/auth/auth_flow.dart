import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../domain/repositories/auth_repository.dart';
import '../../providers/consent_providers.dart';
import '../sync_consent_screen.dart';

/// Mensagem em português para cada falha de autenticação.
String authFailureMessage(AuthFailureCode code) => switch (code) {
  AuthFailureCode.invalidEmail => 'Esse e-mail não é válido.',
  AuthFailureCode.wrongCredentials => 'E-mail ou senha incorretos.',
  AuthFailureCode.emailInUse => 'Já existe uma conta com esse e-mail.',
  AuthFailureCode.weakPassword =>
    'Senha fraca. Use pelo menos 6 caracteres.',
  AuthFailureCode.network =>
    'Sem conexão com a internet. Tente de novo mais tarde.',
  AuthFailureCode.tooManyRequests =>
    'Muitas tentativas. Aguarde um pouco e tente de novo.',
  AuthFailureCode.userDisabled => 'Essa conta foi desativada.',
  AuthFailureCode.unknown => 'Não foi possível concluir. Tente de novo.',
};

/// Chamado com e-mail e senha já validados.
typedef AuthSubmit = Future<void> Function(String email, String password);

/// Entra ou cria a conta e segue o fluxo. Falhas viram mensagem na tela.
Future<String?> runAuth(Future<void> Function() action) async {
  try {
    await action();
    return null;
  } on AuthFailure catch (failure) {
    return authFailureMessage(failure.code);
  } catch (_) {
    return authFailureMessage(AuthFailureCode.unknown);
  }
}

/// Depois do login ou do cadastro: volta para a raiz e, se o usuário ainda não
/// autorizou o envio, mostra a tela de consentimento. Sem consentimento nada
/// é enviado e o app segue funcionando só neste aparelho.
void finishAuthFlow(BuildContext context, WidgetRef ref) {
  final navigator = Navigator.of(context);
  final hasConsent = ref.read(syncConsentControllerProvider);
  navigator.popUntil((route) => route.isFirst);
  if (!hasConsent) {
    navigator.push(
      MaterialPageRoute<void>(builder: (_) => const SyncConsentScreen()),
    );
  }
}

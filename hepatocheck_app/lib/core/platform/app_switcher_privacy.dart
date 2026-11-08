import 'package:flutter/services.dart';

/// Impede que o Android exponha a prévia do app nas telas recentes enquanto o
/// Modo Camuflagem estiver bloqueado.
abstract final class AppSwitcherPrivacy {
  static const _channel = MethodChannel('br.com.hepatocheck/app_privacy');

  static Future<void> setProtection(bool enabled) async {
    try {
      await _channel.invokeMethod<void>('setAppSwitcherProtection', {
        'enabled': enabled,
      });
    } on MissingPluginException {
      // A proteção nativa é aplicável ao Android. As demais plataformas seguem
      // com a troca visual para a calculadora ao ir para o segundo plano.
    }
  }
}

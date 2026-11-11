/// Validações dos campos de login e cadastro. Retornam a mensagem de erro,
/// ou nulo quando o valor é válido (formato esperado pelo [FormField]).
abstract final class AuthValidators {
  static final _email = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]{2,}$');

  /// O Firebase Authentication exige no mínimo 6 caracteres.
  static const minPasswordLength = 6;

  static String? email(String? value) {
    final text = value?.trim() ?? '';
    if (text.isEmpty) return 'Informe o e-mail.';
    if (!_email.hasMatch(text)) return 'Informe um e-mail válido.';
    return null;
  }

  static String? password(String? value) {
    final text = value ?? '';
    if (text.isEmpty) return 'Informe a senha.';
    if (text.length < minPasswordLength) {
      return 'A senha precisa ter no mínimo $minPasswordLength caracteres.';
    }
    return null;
  }

  static String? confirmPassword(String? value, String password) {
    if (value == null || value.isEmpty) return 'Confirme a senha.';
    if (value != password) return 'As senhas não conferem.';
    return null;
  }
}

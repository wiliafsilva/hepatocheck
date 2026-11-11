import 'package:flutter_test/flutter_test.dart';
import 'package:hepatocheck_app/presentation/screens/auth/auth_validators.dart';

void main() {
  test('e-mail vazio, inválido e válido', () {
    expect(AuthValidators.email(null), isNotNull);
    expect(AuthValidators.email('  '), isNotNull);
    expect(AuthValidators.email('abc'), isNotNull);
    expect(AuthValidators.email('a@b'), isNotNull);
    expect(AuthValidators.email('a b@c.com'), isNotNull);
    expect(AuthValidators.email(' ana@exemplo.com '), isNull);
  });

  test('senha vazia, curta e válida', () {
    expect(AuthValidators.password(''), isNotNull);
    expect(AuthValidators.password('12345'), isNotNull);
    expect(AuthValidators.password('123456'), isNull);
  });

  test('confirmação precisa ser igual à senha', () {
    expect(AuthValidators.confirmPassword('', '123456'), isNotNull);
    expect(AuthValidators.confirmPassword('654321', '123456'), isNotNull);
    expect(AuthValidators.confirmPassword('123456', '123456'), isNull);
  });
}

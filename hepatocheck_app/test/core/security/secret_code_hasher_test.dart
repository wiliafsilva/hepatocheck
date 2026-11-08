import 'package:flutter_test/flutter_test.dart';
import 'package:hepatocheck_app/core/security/secret_code_hasher.dart';

void main() {
  test('guarda somente um hash determinístico do código secreto', () {
    const code = '2580';

    final hash = SecretCodeHasher.hash(code);

    expect(hash, SecretCodeHasher.hash(code));
    expect(hash, isNot(code));
    expect(SecretCodeHasher.hash('2581'), isNot(hash));
  });
}

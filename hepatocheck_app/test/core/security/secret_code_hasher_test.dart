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

  test('a verificação com chave não pode ser comparada ao hash simples', () {
    final protectedHash = SecretCodeHasher.keyedHash(
      code: '2580',
      key: 'chave-guardada-no-armazenamento-seguro',
    );

    expect(protectedHash, isNot(SecretCodeHasher.hash('2580')));
    expect(
      protectedHash,
      isNot(
        SecretCodeHasher.keyedHash(code: '2580', key: 'uma-chave-diferente'),
      ),
    );
  });
}

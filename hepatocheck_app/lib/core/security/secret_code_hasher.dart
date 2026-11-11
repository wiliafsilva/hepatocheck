import 'dart:convert';

import 'package:crypto/crypto.dart';

/// Produz uma representação não reversível do código do Modo Camuflagem.
abstract final class SecretCodeHasher {
  static String hash(String code) =>
      sha256.convert(utf8.encode(code)).toString();

  static String keyedHash({required String code, required String key}) =>
      Hmac(sha256, utf8.encode(key)).convert(utf8.encode(code)).toString();
}

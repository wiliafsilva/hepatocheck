import '../entities/auth_user.dart';

enum AuthFailureCode {
  invalidEmail,
  wrongCredentials,
  emailInUse,
  weakPassword,
  network,
  tooManyRequests,
  userDisabled,
  unknown,
}

class AuthFailure implements Exception {
  const AuthFailure(this.code);

  final AuthFailureCode code;

  @override
  String toString() => 'AuthFailure($code)';
}

/// Contrato da autenticação. A conta é opcional: sem ela o app funciona em
/// modo convidado (RF08) e só a sincronização exige login.
abstract interface class AuthRepository {
  AuthUser? get currentUser;

  Stream<AuthUser?> authStateChanges();

  Future<AuthUser> signIn({required String email, required String password});

  Future<AuthUser> register({required String email, required String password});

  Future<void> sendPasswordReset(String email);

  Future<void> signOut();
}

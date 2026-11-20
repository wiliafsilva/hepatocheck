import 'package:firebase_auth/firebase_auth.dart';

import '../../domain/entities/auth_user.dart';
import '../../domain/repositories/auth_repository.dart';

class FirebaseAuthRepository implements AuthRepository {
  FirebaseAuthRepository(this._auth);

  final FirebaseAuth _auth;

  static AuthUser? _map(User? user) =>
      user == null ? null : AuthUser(uid: user.uid, email: user.email);

  static AuthFailureCode codeFor(String firebaseCode) => switch (firebaseCode) {
    'invalid-email' => AuthFailureCode.invalidEmail,
    'user-not-found' ||
    'wrong-password' ||
    'invalid-credential' => AuthFailureCode.wrongCredentials,
    'email-already-in-use' => AuthFailureCode.emailInUse,
    'weak-password' => AuthFailureCode.weakPassword,
    'network-request-failed' => AuthFailureCode.network,
    'too-many-requests' => AuthFailureCode.tooManyRequests,
    'user-disabled' => AuthFailureCode.userDisabled,
    _ => AuthFailureCode.unknown,
  };

  @override
  AuthUser? get currentUser => _map(_auth.currentUser);

  @override
  Stream<AuthUser?> authStateChanges() => _auth.authStateChanges().map(_map);

  @override
  Future<AuthUser> signIn({
    required String email,
    required String password,
  }) async {
    try {
      final credential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return _map(credential.user)!;
    } on FirebaseAuthException catch (error) {
      throw AuthFailure(codeFor(error.code));
    }
  }

  @override
  Future<AuthUser> register({
    required String email,
    required String password,
  }) async {
    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      return _map(credential.user)!;
    } on FirebaseAuthException catch (error) {
      throw AuthFailure(codeFor(error.code));
    }
  }

  @override
  Future<void> sendPasswordReset(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } on FirebaseAuthException catch (error) {
      // Não revela se o e-mail tem conta.
      if (error.code == 'user-not-found') return;
      throw AuthFailure(codeFor(error.code));
    }
  }

  @override
  Future<AuthUser> reauthenticate(String password) async {
    final user = _auth.currentUser;
    final email = user?.email;
    if (user == null || email == null) {
      throw const AuthFailure(AuthFailureCode.wrongCredentials);
    }
    try {
      final credential = await user.reauthenticateWithCredential(
        EmailAuthProvider.credential(email: email, password: password),
      );
      return _map(credential.user ?? user)!;
    } on FirebaseAuthException catch (error) {
      throw AuthFailure(codeFor(error.code));
    }
  }

  @override
  Future<void> updatePassword(String newPassword) async {
    final user = _auth.currentUser;
    if (user == null) throw const AuthFailure(AuthFailureCode.unknown);
    try {
      await user.updatePassword(newPassword);
    } on FirebaseAuthException catch (error) {
      throw AuthFailure(codeFor(error.code));
    }
  }

  @override
  Future<void> deleteAccount() async {
    final user = _auth.currentUser;
    if (user == null) throw const AuthFailure(AuthFailureCode.unknown);
    try {
      await user.delete();
    } on FirebaseAuthException catch (error) {
      throw AuthFailure(codeFor(error.code));
    }
  }

  @override
  Future<void> signOut() => _auth.signOut();
}

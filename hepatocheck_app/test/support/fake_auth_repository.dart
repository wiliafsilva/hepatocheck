import 'dart:async';

import 'package:hepatocheck_app/domain/entities/auth_user.dart';
import 'package:hepatocheck_app/domain/repositories/auth_repository.dart';
import 'package:hepatocheck_app/domain/repositories/sync_consent_repository.dart';

class FakeAuthRepository implements AuthRepository {
  FakeAuthRepository({this.failure});

  AuthFailureCode? failure;
  AuthUser? _user;
  final _controller = StreamController<AuthUser?>.broadcast();
  final resetEmails = <String>[];

  @override
  AuthUser? get currentUser => _user;

  @override
  Stream<AuthUser?> authStateChanges() => _controller.stream;

  void _emit(AuthUser? user) {
    _user = user;
    _controller.add(user);
  }

  @override
  Future<AuthUser> signIn({
    required String email,
    required String password,
  }) async {
    if (failure != null) throw AuthFailure(failure!);
    final user = AuthUser(uid: 'uid-1', email: email);
    _emit(user);
    return user;
  }

  @override
  Future<AuthUser> register({
    required String email,
    required String password,
  }) => signIn(email: email, password: password);

  @override
  Future<void> sendPasswordReset(String email) async {
    if (failure != null) throw AuthFailure(failure!);
    resetEmails.add(email);
  }

  String password = '123456';
  final passwordChanges = <String>[];
  bool failUpdate = false;

  @override
  Future<AuthUser> reauthenticate(String password) async {
    final user = _user;
    if (user == null || password != this.password) {
      throw const AuthFailure(AuthFailureCode.wrongCredentials);
    }
    return user;
  }

  @override
  Future<void> updatePassword(String newPassword) async {
    if (failUpdate) throw const AuthFailure(AuthFailureCode.network);
    password = newPassword;
    passwordChanges.add(newPassword);
  }

  bool deleted = false;

  @override
  Future<void> deleteAccount() async {
    deleted = true;
    _emit(null);
  }

  @override
  Future<void> signOut() async => _emit(null);
}

class MemorySyncConsentRepository implements SyncConsentRepository {
  DateTime? _grantedAt;

  @override
  DateTime? get grantedAt => _grantedAt;

  @override
  bool get isGranted => _grantedAt != null;

  @override
  Future<void> grant(DateTime at) async => _grantedAt = at;

  @override
  Future<void> revoke() async => _grantedAt = null;
}

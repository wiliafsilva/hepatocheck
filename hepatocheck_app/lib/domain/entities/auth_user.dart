/// Usuário autenticado. O e-mail só é exibido no aparelho; nunca vai para o
/// Firestore (ver [AnonymizeSyncPayload]).
class AuthUser {
  const AuthUser({required this.uid, this.email});

  final String uid;
  final String? email;
}

/// Consentimento do usuário para enviar os dados à nuvem (RF11, LGPD).
abstract interface class SyncConsentRepository {
  bool get isGranted;

  DateTime? get grantedAt;

  Future<void> grant(DateTime at);

  Future<void> revoke();
}

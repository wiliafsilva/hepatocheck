class UserPreferences {
  const UserPreferences({
    this.camouflageEnabled = false,
    this.camouflageCodeHash,
    this.syncConsent = false,
    this.remindersEnabled = true,
  });

  final bool camouflageEnabled;
  final String? camouflageCodeHash;
  final bool syncConsent;
  final bool remindersEnabled;

  UserPreferences copyWith({
    bool? camouflageEnabled,
    String? camouflageCodeHash,
    bool? syncConsent,
    bool? remindersEnabled,
  }) {
    return UserPreferences(
      camouflageEnabled: camouflageEnabled ?? this.camouflageEnabled,
      camouflageCodeHash: camouflageCodeHash ?? this.camouflageCodeHash,
      syncConsent: syncConsent ?? this.syncConsent,
      remindersEnabled: remindersEnabled ?? this.remindersEnabled,
    );
  }
}

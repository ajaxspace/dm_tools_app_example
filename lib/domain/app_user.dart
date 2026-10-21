/// Identity provider used to authenticate an [AppUser].
enum AuthProvider { google, apple }

/// A signed-in account, normalized across the Google and Apple sign-in
/// flows so the rest of the app is provider-agnostic.
class AppUser {
  const AppUser({
    required this.id,
    required this.provider,
    this.displayName,
    this.email,
  });

  /// Stable provider-specific account identifier.
  final String id;

  /// Which provider produced this account.
  final AuthProvider provider;

  /// Profile display name, if the provider disclosed one.
  ///
  /// Apple only returns it on the first authorization; later credentials
  /// carry just the identifier, so this is nullable by design.
  final String? displayName;

  /// Profile email, if the provider disclosed one.
  final String? email;

  AppUser copyWith({String? displayName, String? email}) {
    return AppUser(
      id: id,
      provider: provider,
      displayName: displayName ?? this.displayName,
      email: email ?? this.email,
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id': id,
      'provider': provider.name,
      if (displayName != null) 'displayName': displayName,
      if (email != null) 'email': email,
    };
  }

  factory AppUser.fromJson(Map<String, dynamic> json) {
    final String providerName = json['provider'] as String;
    final AuthProvider provider = AuthProvider.values.firstWhere(
      (AuthProvider value) => value.name == providerName,
      orElse: () => throw ArgumentError.value(
        providerName,
        'provider',
        'Unknown auth provider',
      ),
    );

    return AppUser(
      id: json['id'] as String,
      provider: provider,
      displayName: json['displayName'] as String?,
      email: json['email'] as String?,
    );
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is AppUser &&
            other.id == id &&
            other.provider == provider &&
            other.displayName == displayName &&
            other.email == email;
  }

  @override
  int get hashCode => Object.hash(id, provider, displayName, email);

  @override
  String toString() => 'AppUser(${provider.name}, $id, $displayName, $email)';
}

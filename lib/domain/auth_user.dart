/// How the user authenticated.
enum AuthProvider {
  email,
  google,
  apple;

  String get label => switch (this) {
        AuthProvider.email => 'Email',
        AuthProvider.google => 'Google',
        AuthProvider.apple => 'Apple',
      };
}

/// A signed-in user, independent of the underlying identity provider.
class AuthUser {
  const AuthUser({
    required this.id,
    required this.email,
    required this.provider,
    this.displayName,
  });

  factory AuthUser.fromJson(Map<String, Object?> json) => AuthUser(
        id: json['id']! as String,
        email: json['email'] as String?,
        displayName: json['displayName'] as String?,
        provider: AuthProvider.values.byName(json['provider']! as String),
      );

  /// Provider-specific stable identifier.
  final String id;

  /// May be null for Apple sign-in re-authorizations, where Apple only
  /// shares the email on the first authorization.
  final String? email;

  final String? displayName;

  final AuthProvider provider;

  /// Best-effort display name for UI purposes.
  String get displayNameOrEmail => (displayName?.isNotEmpty ?? false)
      ? displayName!
      : (email?.isNotEmpty ?? false)
          ? email!
          : provider.label;

  Map<String, Object?> toJson() => <String, Object?>{
        'id': id,
        'email': email,
        'displayName': displayName,
        'provider': provider.name,
      };

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AuthUser &&
          other.id == id &&
          other.email == email &&
          other.displayName == displayName &&
          other.provider == provider;

  @override
  int get hashCode => Object.hash(id, email, displayName, provider);

  @override
  String toString() =>
      'AuthUser(id: $id, email: $email, provider: ${provider.name})';
}

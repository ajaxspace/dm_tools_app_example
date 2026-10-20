/// Shared client-side credential validation rules.
///
/// Used by both the login form (field-level errors) and the auth layer
/// (defensive re-check before calling a gateway).
abstract final class CredentialsValidator {
  static final RegExp _email = RegExp(r'^[\w.+-]+@[\w-]+(\.[\w-]+)+$');

  static bool isValidEmail(String value) => _email.hasMatch(value.trim());

  static bool isValidPassword(String value) => value.length >= 6;
}

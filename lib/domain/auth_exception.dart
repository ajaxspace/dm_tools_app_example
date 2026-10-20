/// Generic authentication failure with a user-presentable message.
class AuthException implements Exception {
  const AuthException(this.message);

  final String message;

  @override
  String toString() => 'AuthException: $message';
}

/// The user aborted the flow (dismissed the account picker, cancelled the
/// platform dialog, ...). Not an error condition for the UI.
class AuthCancelledException extends AuthException {
  const AuthCancelledException([super.message = 'Sign-in was cancelled.']);
}

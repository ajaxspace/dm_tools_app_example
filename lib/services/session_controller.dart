import 'package:dm_tools_app_example/domain/app_user.dart';
import 'package:dm_tools_app_example/services/auth_service.dart';
import 'package:dm_tools_app_example/services/session_store.dart';
import 'package:flutter/foundation.dart';

/// Lifecycle phase of the session.
enum SessionStatus {
  /// The remembered account is being loaded; the UI shows a splash.
  restoring,

  /// No account is signed in; the UI shows the login page.
  signedOut,

  /// An account is signed in; the UI shows the home page.
  signedIn,
}

/// Holds the app-wide session state and orchestrates the sign-in,
/// restore and sign-out flows over the [AuthService] and [SessionStore].
///
/// The widget tree listens via [ChangeNotifier]; every state transition
/// notifies listeners.
class SessionController extends ChangeNotifier {
  SessionController({required AuthService authService, required SessionStore sessionStore})
      : _authService = authService,
        _sessionStore = sessionStore;

  final AuthService _authService;
  final SessionStore _sessionStore;

  SessionStatus _status = SessionStatus.restoring;
  AppUser? _user;
  String? _error;
  bool _busy = false;

  /// Current lifecycle phase.
  SessionStatus get status => _status;

  /// The signed-in account, or `null` while signed out.
  AppUser? get user => _user;

  /// Description of the last failed sign-in attempt, if any.
  String? get error => _error;

  /// Whether a sign-in or sign-out flow is in flight.
  bool get busy => _busy;

  /// Loads the remembered account, if any. Safe to call more than once;
  /// later calls are no-ops.
  Future<void> restore() async {
    if (_status != SessionStatus.restoring) {
      return;
    }

    final AppUser? remembered = await _sessionStore.load();
    if (remembered != null) {
      _user = remembered;
      _status = SessionStatus.signedIn;
    } else {
      _status = SessionStatus.signedOut;
    }
    notifyListeners();
  }

  /// Runs the Google sign-in flow. When [remember] is on, the account is
  /// persisted and restored on the next app start.
  Future<void> signInWithGoogle({required bool remember}) {
    return _signIn(() => _authService.signInWithGoogle(), remember);
  }

  /// Runs the Apple sign-in flow. When [remember] is on, the account is
  /// persisted and restored on the next app start.
  Future<void> signInWithApple({required bool remember}) {
    return _signIn(() => _authService.signInWithApple(), remember);
  }

  /// Signs out and clears the remembered account.
  Future<void> signOut() async {
    _busy = true;
    notifyListeners();

    await _authService.signOut();
    await _sessionStore.clear();

    _user = null;
    _error = null;
    _busy = false;
    _status = SessionStatus.signedOut;
    notifyListeners();
  }

  Future<void> _signIn(
    Future<AppUser?> Function() flow,
    bool remember,
  ) async {
    _busy = true;
    _error = null;
    notifyListeners();

    try {
      final AppUser? account = await flow();
      if (account == null) {
        // The user backed out of the provider flow; not an error.
        return;
      }

      _user = account;
      _status = SessionStatus.signedIn;
      if (remember) {
        await _sessionStore.save(account);
      }
    } on Exception catch (exception) {
      _error = exception.toString();
    } finally {
      _busy = false;
      notifyListeners();
    }
  }
}

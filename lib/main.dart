import 'package:dm_tools_app_example/domain/auth_user.dart';
import 'package:dm_tools_app_example/services/auth_service.dart';
import 'package:dm_tools_app_example/services/default_auth_gateway.dart';
import 'package:dm_tools_app_example/services/default_auth_service.dart';
import 'package:dm_tools_app_example/services/session_store.dart';
import 'package:dm_tools_app_example/ui/home_page.dart';
import 'package:dm_tools_app_example/ui/login_page.dart';
import 'package:flutter/material.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final authService = DefaultAuthService(
    gateway: DefaultAuthGateway(),
    sessionStore: SessionStore(),
  );
  runApp(DmToolsApp(authService: authService));
}

/// Root widget: restores a persisted session ("remember me") on startup and
/// routes to [HomePage] or [LoginPage] accordingly.
class DmToolsApp extends StatefulWidget {
  const DmToolsApp({super.key, this.authService});

  /// Overridable for tests; defaults to the production wiring.
  final AuthService? authService;

  @override
  State<DmToolsApp> createState() => _DmToolsAppState();
}

class _DmToolsAppState extends State<DmToolsApp> {
  late AuthService _authService;
  late Future<AuthUser?> _session;
  bool? _appleAvailable;

  AuthService get _service => widget.authService ?? _authService;

  @override
  void initState() {
    super.initState();
    _authService = DefaultAuthService(
      gateway: DefaultAuthGateway(),
      sessionStore: SessionStore(),
    );
    _session = _service.restoreSession();
    _resolveAppleAvailability();
  }

  Future<void> _resolveAppleAvailability() async {
    try {
      final available = await SignInWithApple.isAvailable();
      if (mounted) setState(() => _appleAvailable = available);
    } on Exception {
      if (mounted) setState(() => _appleAvailable = false);
    }
  }

  void _onAuthenticated(AuthUser user) {
    setState(() {
      _session = Future.value(user);
    });
  }

  void _onSignedOut() {
    setState(() {
      _session = Future.value(null);
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'DM Tools',
      theme: ThemeData(colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo)),
      home: FutureBuilder<AuthUser?>(
        future: _session,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }
          final user = snapshot.data;
          if (user != null) {
            return HomePage(
              user: user,
              authService: _service,
              onSignedOut: _onSignedOut,
            );
          }
          return LoginPage(
            authService: _service,
            appleSignInAvailable: _appleAvailable ?? true,
            onAuthenticated: _onAuthenticated,
          );
        },
      ),
    );
  }
}

import 'package:dm_tools_app_example/services/auth_service.dart';
import 'package:dm_tools_app_example/services/session_controller.dart';
import 'package:dm_tools_app_example/services/session_store.dart';
import 'package:dm_tools_app_example/ui/home_page.dart';
import 'package:dm_tools_app_example/ui/login_page.dart';
import 'package:flutter/material.dart';

void main() {
  runApp(const DmToolsApp());
}

/// Root widget: wires the real dependencies and routes between the splash,
/// login and home pages based on the session state.
class DmToolsApp extends StatefulWidget {
  const DmToolsApp({super.key, this.sessionController});

  /// Injectable for tests; defaults to the real auth + preference-backed
  /// session stack.
  final SessionController? sessionController;

  @override
  State<DmToolsApp> createState() => _DmToolsAppState();
}

class _DmToolsAppState extends State<DmToolsApp> {
  late final SessionController _controller =
      widget.sessionController ??
      SessionController(
        authService: GoogleAppleAuthService(),
        sessionStore: SharedPreferencesSessionStore(),
      );

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _controller.restore();
    });
  }

  @override
  void dispose() {
    // Dispose only controllers we own; injected ones belong to the test.
    if (widget.sessionController == null) {
      _controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'DM Tools',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: ListenableBuilder(
        listenable: _controller,
        builder: (BuildContext context, Widget? _) {
          return switch (_controller.status) {
            SessionStatus.restoring => const Scaffold(
                body: Center(child: CircularProgressIndicator()),
              ),
            SessionStatus.signedOut => LoginPage(controller: _controller),
            SessionStatus.signedIn => HomePage(controller: _controller),
          };
        },
      ),
    );
  }
}

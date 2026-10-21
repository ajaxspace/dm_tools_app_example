import 'package:dm_tools_app_example/services/session_controller.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

/// Whether the current platform supports Apple sign-in.
///
/// Platform convention per the ticket: Apple on Apple devices only,
/// Google everywhere.
bool get appleSignInAvailable {
  return defaultTargetPlatform == TargetPlatform.iOS ||
      defaultTargetPlatform == TargetPlatform.macOS;
}

/// Login page: social sign-in buttons plus the remember-me toggle.
class LoginPage extends StatefulWidget {
  const LoginPage({super.key, required this.controller});

  final SessionController controller;

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  bool _rememberMe = false;

  void _signIn(Future<void> Function({required bool remember}) flow) {
    flow(remember: _rememberMe);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: ListenableBuilder(
          listenable: widget.controller,
          builder: (BuildContext context, Widget? _) {
            final SessionController controller = widget.controller;
            final bool busy = controller.busy;

            return Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 360),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: <Widget>[
                      Icon(
                        Icons.lock_outline,
                        size: 56,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Sign in to continue',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                      const SizedBox(height: 32),
                      if (busy) ...<Widget>[
                        const Center(
                          child: SizedBox(
                            key: Key('login_progress'),
                            width: 28,
                            height: 28,
                            child: CircularProgressIndicator(strokeWidth: 3),
                          ),
                        ),
                        const SizedBox(height: 24),
                      ] else ...<Widget>[
                        OutlinedButton.icon(
                          key: const Key('google_sign_in_button'),
                          onPressed: () =>
                              _signIn(controller.signInWithGoogle),
                          icon: const _GoogleGlyph(),
                          label: const Text('Sign in with Google'),
                        ),
                        if (appleSignInAvailable) ...<Widget>[
                          const SizedBox(height: 12),
                          SignInWithAppleButton(
                            onPressed: () =>
                                _signIn(controller.signInWithApple),
                            style: SignInWithAppleButtonStyle.black,
                            height: 48,
                          ),
                        ],
                        SwitchListTile(
                          key: const Key('remember_me_toggle'),
                          title: const Text('Remember me'),
                          subtitle:
                              const Text('Stay signed in on this device'),
                          value: _rememberMe,
                          onChanged: (bool value) =>
                              setState(() => _rememberMe = value),
                        ),
                      ],
                      if (controller.error != null) ...<Widget>[
                        const SizedBox(height: 16),
                        Text(
                          key: const Key('login_error_text'),
                          'Sign-in failed: ${controller.error}',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.error,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

/// Minimal brand mark for the Google button (single-color "G" glyph).
class _GoogleGlyph extends StatelessWidget {
  const _GoogleGlyph();

  @override
  Widget build(BuildContext context) {
    return const Text(
      'G',
      style: TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w700,
        color: Color(0xFF4285F4),
      ),
    );
  }
}

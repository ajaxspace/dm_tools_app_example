import 'package:dm_tools_app_example/domain/auth_exception.dart';
import 'package:dm_tools_app_example/domain/auth_user.dart';
import 'package:dm_tools_app_example/domain/credentials_validator.dart';
import 'package:dm_tools_app_example/services/auth_service.dart';
import 'package:dm_tools_app_example/ui/app_logo.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

/// Login page: email/password form with validation and error states,
/// a "Remember me" toggle, and federated Google / Apple sign-in.
///
/// Credentials are offered to the platform password managers for saving /
/// autofill via an [AutofillGroup] and [TextInput.finishAutofillContext]
/// (where the platform supports it).
class LoginPage extends StatefulWidget {
  const LoginPage({
    super.key,
    required this.authService,
    this.appleSignInAvailable = true,
    this.onAuthenticated,
  });

  final AuthService authService;

  /// Whether the platform offers Sign in with Apple (iOS 13+ / macOS).
  /// The button is hidden otherwise, per Apple's guidelines.
  final bool appleSignInAvailable;

  /// Called after a successful sign-in with any provider.
  final ValueChanged<AuthUser>? onAuthenticated;

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _remember = true;
  bool _busy = false;
  bool _obscurePassword = true;
  String? _errorMessage;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _runSignIn({
    bool validateForm = false,
    required Future<AuthUser> Function(bool remember) action,
  }) async {
    if (_busy) return;
    if (validateForm && !(_formKey.currentState?.validate() ?? false)) return;

    setState(() => _errorMessage = null);
    setState(() => _busy = true);
    try {
      final user = await action(_remember);
      if (validateForm) {
        // Let the platform password manager save the credentials.
        TextInput.finishAutofillContext(shouldSave: true);
      }
      widget.onAuthenticated?.call(user);
    } on AuthCancelledException {
      // User dismissed the provider UI — not an error.
    } on AuthException catch (e) {
      if (mounted) setState(() => _errorMessage = e.message);
    } catch (_) {
      if (mounted) {
        setState(() => _errorMessage = 'Sign-in failed. Please try again.');
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _signInWithEmail() => _runSignIn(
        validateForm: true,
        action: (remember) => widget.authService.signInWithEmail(
          _emailController.text,
          _passwordController.text,
          remember: remember,
        ),
      );

  Future<void> _signInWithGoogle() =>
      _runSignIn(action: (remember) => widget.authService.signInWithGoogle(
            remember: remember,
          ));

  Future<void> _signInWithApple() =>
      _runSignIn(action: (remember) => widget.authService.signInWithApple(
            remember: remember,
          ));

  String? _validateEmail(String? value) {
    final email = value?.trim() ?? '';
    if (email.isEmpty) return 'Enter your email';
    if (!CredentialsValidator.isValidEmail(email)) {
      return 'Enter a valid email address';
    }
    return null;
  }

  String? _validatePassword(String? value) {
    final password = value ?? '';
    if (password.isEmpty) return 'Enter your password';
    if (!CredentialsValidator.isValidPassword(password)) {
      return 'Password must be at least 6 characters';
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 400),
              child: AutofillGroup(
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Center(
                        child: AppLogo(key: Key('login_app_logo')),
                      ),
                      const SizedBox(height: 24),
                      Text(
                        'Welcome back',
                        style: Theme.of(context).textTheme.headlineSmall,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 24),
                      if (_errorMessage != null) ...[
                        _ErrorBanner(
                          key: const Key('login_error_banner'),
                          message: _errorMessage!,
                        ),
                        const SizedBox(height: 16),
                      ],
                      TextFormField(
                        key: const Key('login_email_field'),
                        controller: _emailController,
                        decoration: const InputDecoration(
                          labelText: 'Email',
                          prefixIcon: Icon(Icons.email_outlined),
                          border: OutlineInputBorder(),
                        ),
                        keyboardType: TextInputType.emailAddress,
                        autofillHints: const [AutofillHints.email],
                        textInputAction: TextInputAction.next,
                        enabled: !_busy,
                        validator: _validateEmail,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        key: const Key('login_password_field'),
                        controller: _passwordController,
                        obscureText: _obscurePassword,
                        decoration: InputDecoration(
                          labelText: 'Password',
                          prefixIcon: const Icon(Icons.lock_outline),
                          border: const OutlineInputBorder(),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscurePassword
                                  ? Icons.visibility_outlined
                                  : Icons.visibility_off_outlined,
                            ),
                            onPressed: () => setState(
                                () => _obscurePassword = !_obscurePassword),
                          ),
                        ),
                        autofillHints: const [AutofillHints.password],
                        textInputAction: TextInputAction.done,
                        enabled: !_busy,
                        validator: _validatePassword,
                        onFieldSubmitted: (_) => _signInWithEmail(),
                      ),
                      CheckboxListTile(
                        key: const Key('login_remember_me'),
                        value: _remember,
                        onChanged: _busy
                            ? null
                            : (value) =>
                                setState(() => _remember = value ?? false),
                        title: const Text('Remember me'),
                        controlAffinity: ListTileControlAffinity.leading,
                        contentPadding: EdgeInsets.zero,
                      ),
                      const SizedBox(height: 8),
                      FilledButton(
                        key: const Key('login_submit_button'),
                        onPressed: _busy ? null : _signInWithEmail,
                        child: _busy
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2),
                              )
                            : const Text('Sign in'),
                      ),
                      const _OrDivider(),
                      OutlinedButton.icon(
                        key: const Key('login_google_button'),
                        onPressed: _busy ? null : _signInWithGoogle,
                        icon: const Icon(Icons.account_circle_outlined),
                        label: const Text('Continue with Google'),
                      ),
                      if (widget.appleSignInAvailable) ...[
                        const SizedBox(height: 12),
                        SignInWithAppleButton(
                          key: const Key('login_apple_button'),
                          onPressed: _busy ? null : _signInWithApple,
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  const _ErrorBanner({super.key, required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: scheme.errorContainer,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline, color: scheme.onErrorContainer),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: TextStyle(color: scheme.onErrorContainer),
            ),
          ),
        ],
      ),
    );
  }
}

class _OrDivider extends StatelessWidget {
  const _OrDivider();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 20),
      child: Row(
        children: [
          const Expanded(child: Divider()),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Text(
              'or continue with',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
          const Expanded(child: Divider()),
        ],
      ),
    );
  }
}

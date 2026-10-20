import 'package:dm_tools_app_example/domain/auth_user.dart';
import 'package:dm_tools_app_example/services/auth_service.dart';
import 'package:flutter/material.dart';

/// Simple signed-in landing page.
class HomePage extends StatelessWidget {
  const HomePage({
    super.key,
    required this.user,
    required this.authService,
    this.onSignedOut,
  });

  final AuthUser user;
  final AuthService authService;
  final VoidCallback? onSignedOut;

  Future<void> _signOut() async {
    await authService.signOut();
    onSignedOut?.call();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Home')),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircleAvatar(
              radius: 32,
              child: Icon(Icons.person, size: 36),
            ),
            const SizedBox(height: 12),
            Text(
              user.displayNameOrEmail,
              style: theme.textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
            if (user.email != null && user.email!.isNotEmpty)
              Text(user.email!, style: theme.textTheme.bodySmall),
            const SizedBox(height: 8),
            Chip(
              avatar: const Icon(Icons.verified_user_outlined, size: 16),
              label: Text('Signed in via ${user.provider.label}'),
            ),
            const SizedBox(height: 24),
            FilledButton.tonal(
              key: const Key('home_sign_out_button'),
              onPressed: _signOut,
              child: const Text('Sign out'),
            ),
          ],
        ),
      ),
    );
  }
}

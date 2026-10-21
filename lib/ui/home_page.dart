import 'package:dm_tools_app_example/domain/app_user.dart';
import 'package:dm_tools_app_example/services/session_controller.dart';
import 'package:flutter/material.dart';

/// Page shown while an account is signed in: profile details and sign-out.
class HomePage extends StatelessWidget {
  const HomePage({super.key, required this.controller});

  final SessionController controller;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Home'),
        actions: <Widget>[
          IconButton(
            key: const Key('sign_out_button'),
            tooltip: 'Sign out',
            icon: const Icon(Icons.logout),
            onPressed: () => controller.signOut(),
          ),
        ],
      ),
      body: ListenableBuilder(
        listenable: controller,
        builder: (BuildContext context, Widget? _) {
          final AppUser? user = controller.user;
          if (user == null) {
            return const SizedBox.shrink();
          }

          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                CircleAvatar(
                  radius: 40,
                  child: Text(
                    _initialFor(user),
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  _displayNameFor(user),
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                if (user.email != null) ...<Widget>[
                  const SizedBox(height: 4),
                  Text(user.email!),
                ],
                const SizedBox(height: 8),
                Text(
                  'Signed in with ${user.provider.name}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  String _displayNameFor(AppUser user) {
    if (user.displayName != null && user.displayName!.trim().isNotEmpty) {
      return user.displayName!;
    }
    return switch (user.provider) {
      AuthProvider.google => 'Google account',
      AuthProvider.apple => 'Apple account',
    };
  }

  String _initialFor(AppUser user) {
    final String? name = user.displayName;
    if (name != null && name.trim().isNotEmpty) {
      return name.trim()[0].toUpperCase();
    }
    return switch (user.provider) {
      AuthProvider.google => 'G',
      AuthProvider.apple => '',
    };
  }
}

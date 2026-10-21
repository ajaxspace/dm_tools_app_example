import 'package:flutter/material.dart';

/// The application logo asset, shown on the login screen.
///
/// The asset is a square badge; [ClipRRect] rounds it for in-app display
/// (launcher icons use the un-rounded square, as platforms apply their own
/// masks).
class AppLogo extends StatelessWidget {
  const AppLogo({super.key, this.size = 96});

  /// Asset path of the logo image (declared in pubspec.yaml).
  static const String assetName = 'assets/images/app_logo.png';

  /// Square edge length of the rendered logo.
  final double size;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: Image.asset(
        assetName,
        width: size,
        height: size,
        fit: BoxFit.cover,
      ),
    );
  }
}

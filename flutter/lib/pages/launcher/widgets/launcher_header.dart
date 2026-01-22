import 'package:flutter/material.dart';

/// Header section with icon and description
class LauncherHeader extends StatelessWidget {
  const LauncherHeader({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      children: [
        Image.asset(
          'assets/logo/webfly_logo.png',
          width: 80,
          height: 80,
        ),
        const SizedBox(height: 12),
        Text(
          'Enter a URL or scan a QR code to launch',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}

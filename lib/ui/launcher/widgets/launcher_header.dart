import 'package:flutter/material.dart';

/// Header section with icon and description
class LauncherHeader extends StatelessWidget {
  const LauncherHeader({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    // _dark.png for dark theme, _light.png for light theme
    final logoPath = isDark
        ? 'assets/gen/logo/webfly_logo_dark.png'
        : 'assets/gen/logo/webfly_logo_light.png';
    return Column(
      children: [
        Image.asset(
          logoPath,
          width: 120,
          height: 120,
          errorBuilder: (context, error, stackTrace) {
            return const SizedBox(width: 120, height: 120);
          },
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

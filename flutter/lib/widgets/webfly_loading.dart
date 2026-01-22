import 'package:flutter/material.dart';

/// WebFly loading indicator with logo
class WebFlyLoading extends StatelessWidget {
  final String? message;

  const WebFlyLoading({super.key, this.message});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    // _dark.png for dark theme, _light.png for light theme
    final logoPath = isDark
        ? 'assets/logo/webfly_logo_dark.png'
        : 'assets/logo/webfly_logo_light.png';
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Image.asset(logoPath, width: 80, height: 80),
          const SizedBox(height: 24),
          const CircularProgressIndicator(),
          if (message != null) ...[
            const SizedBox(height: 16),
            Text(
              message!,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ],
      ),
    );
  }
}

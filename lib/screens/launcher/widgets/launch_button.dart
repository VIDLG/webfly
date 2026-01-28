import 'package:flutter/material.dart';

/// Launch button
class LauncherButton extends StatelessWidget {
  const LauncherButton({super.key, required this.onLaunch});

  final VoidCallback onLaunch;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: FilledButton.icon(
        onPressed: onLaunch,
        icon: const Icon(Icons.rocket_launch),
        label: const Text('Launch'),
        style: FilledButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 16),
        ),
      ),
    );
  }
}

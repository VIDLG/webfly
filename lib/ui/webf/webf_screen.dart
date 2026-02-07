import 'package:flutter/material.dart';
import 'webf_view.dart';
import 'webf_inspector_overlay.dart';

/// A complete WebF page with Scaffold and AppBar.
///
/// This is a convenience wrapper around WebFView that provides a standard
/// page structure with an app bar and title.
class WebFScreen extends StatelessWidget {
  const WebFScreen({
    super.key,
    required this.url,
    required this.controllerName,
    this.routePath = '/',
    this.title,
    this.loadingBuilder,
    this.errorBuilder,
  });

  final String url;
  final String controllerName;
  final String routePath;
  final String? title;

  /// Optional custom loading widget builder
  final Widget Function(BuildContext)? loadingBuilder;

  /// Optional custom error widget builder
  final Widget Function(BuildContext, Object?)? errorBuilder;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Scaffold(
      // Ensure the scaffold background matches the app theme (WebF is transparent)
      backgroundColor: colorScheme.surface,
      resizeToAvoidBottomInset: false,
      body: SafeArea(
        child: Stack(
          children: [
            WebFView(
              url: url,
              controllerName: controllerName,
              routePath: routePath,
              loadingBuilder: loadingBuilder,
              errorBuilder: errorBuilder,
            ),
            const WebFInspectorOverlay(),
          ],
        ),
      ),
    );
  }
}

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
    this.cacheController,
    this.loadingBuilder,
    this.errorBuilder,
  });

  final String url;
  final String controllerName;
  final String routePath;
  final String? title;
  final bool? cacheController;

  /// Optional custom loading widget builder
  final Widget Function(BuildContext)? loadingBuilder;

  /// Optional custom error widget builder
  final Widget Function(BuildContext, Object?)? errorBuilder;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 48,
        title: title != null
            ? Text(title!, maxLines: 1, overflow: TextOverflow.ellipsis)
            : Text(
                '$url$routePath',
                style: const TextStyle(fontSize: 14),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
      ),
      body: Stack(
        children: [
          WebFView(
            url: url,
            controllerName: controllerName,
            routePath: routePath,
            cacheController: cacheController,
            loadingBuilder: loadingBuilder,
            errorBuilder: errorBuilder,
          ),
          const WebFInspectorOverlay(),
        ],
      ),
    );
  }
}

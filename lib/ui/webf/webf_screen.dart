import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:signals_hooks/signals_hooks.dart';
import 'package:webfly_webf_view/webfly_webf_view.dart';
import 'webf_inspector_overlay.dart';
import '../widgets/webfly_loading.dart';
import '../../store/app_settings.dart';

/// A complete WebF page with Scaffold and AppBar.
///
/// This is a convenience wrapper around WebFView that provides a standard
/// page structure with an app bar and title.
class WebFScreen extends HookWidget {
  const WebFScreen({
    super.key,
    required this.url,
    required this.controllerName,
    this.routePath = '/',
    this.title,
    this.extra,
    this.loadingBuilder,
    this.errorBuilder,
  });

  final String url;
  final String controllerName;
  final String routePath;
  final String? title;

  /// GoRouter extra state passed from the navigation call.
  /// When non-null a small debug bar is briefly displayed at the bottom.
  final Object? extra;

  /// Optional custom loading widget builder
  final Widget Function(BuildContext)? loadingBuilder;

  /// Optional custom error widget builder
  final Widget Function(BuildContext, Object?)? errorBuilder;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final cacheControllers = useSignalValue(cacheControllersSignal);
    final showExtra = useState(extra != null);

    useEffect(() {
      if (!showExtra.value) return null;
      final timer = Timer(const Duration(seconds: 3), () {
        showExtra.value = false;
      });
      return timer.cancel;
    }, [showExtra.value]);

    return Scaffold(
      // Ensure the scaffold background matches the app theme (WebF is transparent)
      backgroundColor: colorScheme.surface,
      resizeToAvoidBottomInset: false,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: Stack(
                children: [
                  WebFView(
                    url: url,
                    controllerName: controllerName,
                    routePath: routePath,
                    cacheControllers: cacheControllers,
                    loadingBuilder:
                        loadingBuilder ??
                        (_) => const WebFlyLoading(message: 'Loading...'),
                    errorBuilder: errorBuilder,
                  ),
                  const WebFInspectorOverlay(),
                ],
              ),
            ),
            if (showExtra.value && extra != null)
              GestureDetector(
                onTap: () => showExtra.value = false,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  color: colorScheme.secondaryContainer,
                  child: Text(
                    'GoRouter extra: ${_formatExtra(extra)}',
                    style: TextStyle(
                      fontSize: 11,
                      color: colorScheme.onSecondaryContainer,
                      fontFamily: 'monospace',
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  static String _formatExtra(Object? value) {
    if (value == null) return 'null';
    try {
      return jsonEncode(value);
    } catch (_) {
      return value.toString();
    }
  }
}

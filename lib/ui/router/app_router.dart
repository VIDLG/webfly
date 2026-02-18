import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:webfly_webf_view/webfly_webf_view.dart';
import '../../utils/app_logger.dart';
import '../launcher/launcher_screen.dart';
import '../native_diagnostics/ble_diagnostics_screen.dart';
import '../native_diagnostics/native_diagnostics_logs_screen.dart';
import '../native_diagnostics/native_diagnostics_screen.dart';
import '../scanner_screen.dart';
import '../webf/webf_screen.dart';
import '../about/about_screen.dart';
import '../launcher/widgets/settings_dialog.dart';
import '../use_cases_menu_screen.dart';
import 'config.dart';

/// Route observer for WebF pages, from webfly_webf_view package.
final webfRouteObserver = defaultWebfRouteObserver;

/// Main app router configuration (using go_router)
///
/// Benefits:
/// 1. Declarative route definitions
/// 2. Supports nested routes and path parameters
/// 3. Automatic deep linking and Web URL handling
final goRouter = GoRouter(
  initialLocation: launcherPath,
  observers: [webfRouteObserver],
  debugLogDiagnostics: true, // Enable debug logging
  redirect: (context, state) {
    // Keep '/_/' working for deep links, but use '/_' as the canonical path.
    if (state.uri.path == launcherAliasPath) {
      return launcherPath;
    }
    return null;
  },
  routes: [
    // Flutter native routes with nested structure
    // Parent route: '/_'
    GoRoute(
      path: launcherPath,
      builder: (context, state) => const LauncherScreen(),
      routes: [
        // Scanner page
        GoRoute(
          path: 'scanner',
          builder: (context, state) => const ScannerScreen(),
        ),

        // Native diagnostics hub with sub-routes
        GoRoute(
          path: 'native-diagnostics',
          builder: (context, state) => const NativeDiagnosticsScreen(),
          routes: [
            // Logs for native diagnostics
            GoRoute(
              path: 'logs',
              builder: (context, state) => const NativeDiagnosticsLogsScreen(),
            ),

            // BLE diagnostics page (native scan, bypass WebF)
            GoRoute(
              path: 'ble',
              builder: (context, state) => const BleDiagnosticsScreen(),
            ),
          ],
        ),

        // Settings page
        GoRoute(
          path: 'settings',
          builder: (context, state) => const SettingsScreen(),
        ),

        // About page
        GoRoute(
          path: 'about',
          builder: (context, state) => const AboutScreen(),
        ),

        // Use Cases Menu
        GoRoute(
          path: 'use_cases_menu',
          builder: (context, state) => const UseCasesMenuScreen(),
        ),

        // Use Cases page with fixed title
        GoRoute(
          path: 'usecases',
          redirect: (context, state) {
            final url = state.uri.queryParameters[urlParam];
            return (url == null || url.isEmpty) ? launcherPath : null;
          },
          builder: (context, state) {
            final url = state.uri.queryParameters[urlParam]!;
            final path = state.uri.queryParameters[locParam] ?? '/';
            final base =
                state.uri.queryParameters[baseParam] ??
                generateDefaultControllerName(url);
            final controllerName = base;

            return WebFScreen(
              url: url,
              controllerName: controllerName,
              routePath: path,
              title: 'Use Cases',
            );
          },
        ),
        // WebF Hybrid Routing
        // Uses /_/app with query parameters: url, base, and path
        GoRoute(
          path: 'app',
          redirect: (context, state) {
            talker.debug('[AppRouter] Hybrid route matched: ${state.uri}');
            talker.debug(
              '[AppRouter] Query params: ${state.uri.queryParameters}',
            );
            final url = state.uri.queryParameters[urlParam];
            if (url == null || url.isEmpty) {
              talker.debug(
                '[AppRouter] Missing URL param, redirecting to launcher',
              );
              return launcherPath; // Redirect to launcher if no URL
            }
            return null; // No redirect, continue to builder
          },
          builder: (context, state) {
            final url = state.uri.queryParameters[urlParam]!; // Safe to use !
            final path = state.uri.queryParameters[locParam] ?? '/';
            final base =
                state.uri.queryParameters[baseParam] ??
                generateDefaultControllerName(url);
            final controllerName = base;
            final title = state.uri.queryParameters[titleParam];

            return WebFScreen(
              url: url,
              controllerName: controllerName,
              routePath: path,
              title: title,
              extra: state.extra,
            );
          },
        ),
      ],
    ),
  ],

  // Error handling
  errorBuilder: (context, state) {
    talker.error(
      '[AppRouter] ERROR - Route not found!\n'
      'URI: ${state.uri}\n'
      'Path: ${state.uri.path}\n'
      'Query: ${state.uri.query}\n'
      'Location: ${state.matchedLocation}',
    );
    return Scaffold(
      appBar: AppBar(title: const Text('Page Not Found')),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              const Text(
                'Route not found',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              Text('URI: ${state.uri}'),
              Text('Path: ${state.uri.path}'),
              Text('Query: ${state.uri.query}'),
              Text('Location: ${state.matchedLocation}'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => context.go(launcherPath),
                child: const Text('Go Home'),
              ),
            ],
          ),
        ),
      ),
    );
  },
);

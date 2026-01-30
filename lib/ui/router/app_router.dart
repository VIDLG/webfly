import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../launcher/launcher_screen.dart';
import '../native_diagnostics/ble_diagnostics_screen.dart';
import '../native_diagnostics/native_diagnostics_logs_screen.dart';
import '../native_diagnostics/native_diagnostics_screen.dart';
import '../scanner_screen.dart';
import '../webf/webf_screen.dart';
import 'go_router_delegate.dart';
import 'config.dart';
import '../../utils/app_logger.dart';

/// Route observer for WebF pages
final kWebfRouteObserver = RouteObserver<PageRoute>();

/// Main app router configuration (using go_router)
///
/// Benefits:
/// 1. Declarative route definitions
/// 2. Supports nested routes and path parameters
/// 3. Automatic deep linking and Web URL handling
final kGoRouter = GoRouter(
  initialLocation: kLauncherPath,
  observers: [kWebfRouteObserver],
  debugLogDiagnostics: true, // Enable debug logging
  redirect: (context, state) {
    // Keep '/_/' working for deep links, but use '/_' as the canonical path.
    if (state.uri.path == kLauncherAliasPath) {
      return kLauncherPath;
    }
    return null;
  },
  routes: [
    // Launcher page
    GoRoute(
      path: kLauncherPath,
      builder: (context, state) => const LauncherScreen(),
    ),

    // Native diagnostics hub
    GoRoute(
      path: kNativeDiagnosticsPath,
      builder: (context, state) => const NativeDiagnosticsScreen(),
    ),

    // Logs for native diagnostics
    GoRoute(
      path: kNativeDiagnosticsLogsPath,
      builder: (context, state) => const NativeDiagnosticsLogsScreen(),
    ),

    // BLE diagnostics page (native scan, bypass WebF)
    GoRoute(
      path: kBleDiagnosticsPath,
      builder: (context, state) => const BleDiagnosticsScreen(),
    ),

    // Scanner page
    GoRoute(
      path: kScannerPath,
      builder: (context, state) => const ScannerScreen(),
    ),

    // Use Cases page with fixed title
    GoRoute(
      path: kUseCasesPath,
      redirect: (context, state) {
        final url = state.uri.queryParameters[kUrlParam];
        return (url == null || url.isEmpty) ? kLauncherPath : null;
      },
      builder: (context, state) {
        final url = state.uri.queryParameters[kUrlParam]!;
        final path = state.uri.queryParameters[kPathParam] ?? '/';
        final base =
            state.uri.queryParameters[kBaseParam] ??
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

    // WebF page (single URL)
    GoRoute(
      path: kWebfRoutePath,
      redirect: (context, state) {
        final url = state.uri.queryParameters[kUrlParam];
        if (url == null || url.isEmpty) {
          return kLauncherPath; // Redirect to launcher if no URL
        }
        return null; // No redirect, continue to builder
      },
      builder: (context, state) {
        final url = state.uri.queryParameters[kUrlParam]!; // Safe to use !
        final controllerName = generateDefaultControllerName(url);

        return WebFScreen(url: url, controllerName: controllerName);
      },
    ),

    // WebF Hybrid Routing
    // Uses /app with query parameters: url, base, and path
    GoRoute(
      path: kAppRoutePath,
      redirect: (context, state) {
        appLogger.d('[AppRouter] Hybrid route matched: ${state.uri}');
        appLogger.d('[AppRouter] Query params: ${state.uri.queryParameters}');
        final url = state.uri.queryParameters[kUrlParam];
        if (url == null || url.isEmpty) {
          appLogger.d('[AppRouter] Missing URL param, redirecting to launcher');
          return kLauncherPath; // Redirect to launcher if no URL
        }
        return null; // No redirect, continue to builder
      },
      builder: (context, state) {
        final url = state.uri.queryParameters[kUrlParam]!; // Safe to use !
        final path = state.uri.queryParameters[kPathParam] ?? '/';
        final base =
            state.uri.queryParameters[kBaseParam] ??
            generateDefaultControllerName(url);
        // Use base as controllerName - all hybrid routes share the same controller
        final controllerName = base;
        final title = state.uri.queryParameters[kTitleParam];

        return WebFScreen(
          url: url,
          controllerName: controllerName,
          routePath: path,
          title: title,
        );
      },
    ),
  ],

  // Error handling
  errorBuilder: (context, state) {
    appLogger.e(
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
                onPressed: () => context.go(kLauncherPath),
                child: const Text('Go Home'),
              ),
            ],
          ),
        ),
      ),
    );
  },
);

/// Global go_router delegate instance
final kGoRouterDelegate = CustomHybridHistoryDelegate();

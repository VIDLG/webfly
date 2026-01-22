import 'dart:convert' show jsonEncode;
import 'package:flutter/material.dart' show BuildContext, RoutePredicate;
import 'package:go_router/go_router.dart';
import 'package:webf/webf.dart' show HybridHistoryDelegate;
import 'package:webfly/utils/app_logger.dart';
import 'config.dart';

/// HybridHistoryDelegate for go_router
///
/// Integrates WebF's Hybrid Routing with go_router
/// Uses go_router's stack directly for WebF navigation
class GoRouterHybridHistoryDelegate extends HybridHistoryDelegate {
  final GoRouter router;

  GoRouterHybridHistoryDelegate(this.router);

  /// Prepare navigation: build route URL from path
  String _prepareNavigation(String path, BuildContext context) {
    appLogger.d('[GoRouterDelegate] _prepareNavigation');
    appLogger.d('[GoRouterDelegate]   path: $path');

    // Get url and base from current page's GoRouterState
    final state = GoRouterState.of(context);
    final url = state.uri.queryParameters['url'];
    final base = state.uri.queryParameters['base'];

    appLogger.d('[GoRouterDelegate]   Current page URI: ${state.uri}');
    appLogger.d('[GoRouterDelegate]   Current page path: ${state.uri.path}');
    appLogger.d('[GoRouterDelegate]   url: $url');
    appLogger.d('[GoRouterDelegate]   base: $base');

    if (url == null || base == null) {
      throw StateError(
        'Current page does not have url/base parameters. URI: ${state.uri}',
      );
    }

    // Build route URL using current page's route
    final routeUrl = buildWebFRouteUrl(
      url: url,
      route: state.uri.path,
      path: path,
      base: base,
    );

    appLogger.d('[GoRouterDelegate]   generated routeUrl: $routeUrl');

    return routeUrl;
  }

  @override
  void pop(BuildContext context) {
    appLogger.d('[GoRouterDelegate] pop called');
    appLogger.d('[GoRouterDelegate]   router.canPop(): ${router.canPop()}');

    if (router.canPop()) {
      appLogger.d('[GoRouterDelegate]   Calling router.pop()');
      router.pop();
    } else {
      appLogger.d('[GoRouterDelegate]   Cannot pop - at root');
    }
  }

  @override
  String path(BuildContext? context, String? initialRoute) {
    if (context != null) {
      try {
        final state = GoRouterState.of(context);
        // Get path from query parameter
        return state.uri.queryParameters['path'] ?? '/';
      } catch (e) {
        appLogger.e('[GoRouterDelegate] Failed to get path from context: $e');
      }
    }
    // Fallback to initialRoute or root
    return initialRoute ?? '/';
  }

  @override
  dynamic state(BuildContext? context, Map<String, dynamic>? initialState) {
    if (context != null) {
      try {
        final goRouterState = GoRouterState.of(context);
        // Return extra state if available
        if (goRouterState.extra != null) {
          return jsonEncode(goRouterState.extra);
        }
        // Return query parameters from current page URI
        final params = goRouterState.uri.queryParameters;
        if (params.isNotEmpty) {
          return jsonEncode(params);
        }
      } catch (e) {
        appLogger.e('[GoRouterDelegate] Failed to get GoRouterState: $e');
      }
    }

    // Fallback to initialState
    return jsonEncode(initialState ?? {});
  }

  @override
  void pushNamed(BuildContext context, String routeName, {Object? arguments}) {
    final routeUrl = _prepareNavigation(routeName, context);
    appLogger.d(
      '[GoRouterDelegate] pushNamed: $routeUrl with arguments: $arguments',
    );

    // Push to Flutter router - WebF and Flutter share the same stack
    router.push(routeUrl, extra: arguments);
  }

  @override
  void replaceState(BuildContext context, Object? state, String name) {
    final routeUrl = _prepareNavigation(name, context);
    appLogger.d(
      '[GoRouterDelegate] replaceState: $routeUrl with state: $state',
    );
    router.replace(routeUrl, extra: state);
  }

  @override
  String restorablePopAndPushNamed<T extends Object?, TO extends Object?>(
    BuildContext context,
    String routeName, {
    TO? result,
    Object? arguments,
  }) {
    appLogger.d('[GoRouterDelegate] restorablePopAndPushNamed: $routeName');
    if (router.canPop()) {
      router.pop();
    }
    pushNamed(context, routeName, arguments: arguments);
    return routeName;
  }

  @override
  void popUntil(BuildContext context, RoutePredicate predicate) {
    // go_router doesn't expose routes directly, use the underlying Navigator
    final navigator = router.routerDelegate.navigatorKey.currentState;
    if (navigator != null) {
      navigator.popUntil(predicate);
    }
  }

  @override
  bool canPop(BuildContext context) {
    // WebF and Flutter share the same route stack
    return router.canPop();
  }

  @override
  Future<bool> maybePop<T extends Object?>(
    BuildContext context, [
    T? result,
  ]) async {
    if (router.canPop()) {
      router.pop();
      return true;
    }
    return false;
  }

  @override
  void popAndPushNamed(
    BuildContext context,
    String routeName, {
    Object? arguments,
  }) {
    appLogger.d('[GoRouterDelegate] popAndPushNamed: $routeName');
    if (router.canPop()) {
      router.pop();
    }
    pushNamed(context, routeName, arguments: arguments);
  }

  @override
  void pushNamedAndRemoveUntil(
    BuildContext context,
    String newRouteName,
    RoutePredicate predicate, {
    Object? arguments,
  }) {
    popUntil(context, predicate);
    pushNamed(context, newRouteName, arguments: arguments);
  }
}

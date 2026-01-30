/*
 * Copyright (C) 2022-present The WebF authors. All rights reserved.
 */

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:webf/webf.dart';

import 'config.dart';

class CustomHybridHistoryDelegate extends HybridHistoryDelegate {
  String _maybeWrapToHybridAppRoute(BuildContext context, String location) {
    assert(() {
      debugPrint('[HybridNav] request location=$location');
      return true;
    }());
    // If it's already one of our Flutter-native routes, keep it as-is.
    // Otherwise, treat it as a WebF internal route and wrap it into `/app?...&path=...`.
    Uri? targetUri;
    try {
      targetUri = Uri.parse(location);
    } catch (_) {
      assert(() {
        debugPrint('[HybridNav] parse failed, passthrough location=$location');
        return true;
      }());
      return location;
    }

    final path = targetUri.path.isEmpty ? kWebfInnerRootPath : targetUri.path;
    if (path.startsWith(kFlutterPrefix) ||
        path == kWebfRoutePath ||
        path == kUseCasesPath ||
        path == kAppRoutePath) {
      assert(() {
        debugPrint('[HybridNav] native route detected path=$path, passthrough');
        return true;
      }());
      return location;
    }

    Uri currentUri;
    try {
      currentUri = GoRouterState.of(context).uri;
    } catch (_) {
      assert(() {
        debugPrint('[HybridNav] cannot read GoRouterState.uri, passthrough location=$location');
        return true;
      }());
      // If we can't read current route context, fall back to raw location.
      return location;
    }

    // Only wrap when we have enough context to build the `/app` URL.
    final url = currentUri.queryParameters[kUrlParam];
    if (url == null || url.isEmpty) {
      assert(() {
        debugPrint('[HybridNav] missing url param in currentUri=$currentUri, passthrough');
        return true;
      }());
      return location;
    }

    // WebF hybrid route expects the internal *location* in query param `path`.
    // Preserve query/fragment so advanced deep-links like `/led?css=0` work.
    final innerLocation = '$path'
      '${targetUri.hasQuery ? '?${targetUri.query}' : ''}'
      '${targetUri.hasFragment ? '#${targetUri.fragment}' : ''}';
    final normalizedPath =
      normalizeWebfInnerPath(innerLocation) ?? kWebfInnerRootPath;
    final wrapped = buildWebFRouteUrlFromUri(
      uri: currentUri,
      route: kAppRoutePath,
      path: normalizedPath,
    );
    assert(() {
      debugPrint('[HybridNav] wrap path=$normalizedPath currentUri=$currentUri -> $wrapped');
      return true;
    }());
    return wrapped;
  }

  @override
  void pop(BuildContext context) {
    if (GoRouter.of(context).canPop()) {
      GoRouter.of(context).pop();
      return;
    }
    Navigator.pop(context);
  }

  @override
  String path(BuildContext? context, String? initialRoute) {
    if (context == null) return initialRoute ?? kLauncherPath;
    try {
      final uri = GoRouterState.of(context).uri;

      assert(() {
        debugPrint('[HybridNav] path() current uri=$uri');
        return true;
      }());

      // Hybrid routing wraps the real web route into query param `path`.
      // For WebF/JS routers we should expose the inner route (e.g. `/led`) rather
      // than the outer Flutter route (e.g. `/app?url=...&path=%2Fled`).
      if (isHybridWrapperRoutePath(uri.path)) {
        final inner = extractHybridInnerPath(uri) ?? kWebfInnerRootPath;
        assert(() {
          debugPrint('[HybridNav] path() wrapper route=${uri.path} inner=$inner');
          return true;
        }());
        return inner;
      }

      return uri.toString();
    } catch (_) {
      String? currentPath = ModalRoute.of(context)?.settings.name;
      return currentPath ?? initialRoute ?? kLauncherPath;
    }
  }

  @override
  void pushNamed(BuildContext context, String routeName, {Object? arguments}) {
    final location = _maybeWrapToHybridAppRoute(context, routeName);
    GoRouter.of(context).push(location, extra: arguments);
  }

  @override
  void replaceState(BuildContext context, Object? state, String name) {
    final location = _maybeWrapToHybridAppRoute(context, name);
    GoRouter.of(context).pushReplacement(location, extra: state);
  }

  @override
  dynamic state(BuildContext? context, Map<String, dynamic>? initialState) {
    if (context == null) {
      return initialState != null ? jsonEncode(initialState) : '{}';
    }
    var route = ModalRoute.of(context);
    if (route?.settings.arguments != null) {
      return jsonEncode(route!.settings.arguments);
    }
    return '{}';
  }

  @override
  String restorablePopAndPushNamed<T extends Object?, TO extends Object?>(
    BuildContext context,
    String routeName, {
    TO? result,
    Object? arguments,
  }) {
    // go_router doesn't support restorable navigation APIs; fall back to a non-restorable equivalent.
    if (GoRouter.of(context).canPop()) {
      GoRouter.of(context).pop();
    }
    final location = _maybeWrapToHybridAppRoute(context, routeName);
    GoRouter.of(context).push(location, extra: arguments);
    return location;
  }

  @override
  void popUntil(BuildContext context, RoutePredicate predicate) {
    final router = GoRouter.of(context);
    final navigator = router.routerDelegate.navigatorKey.currentState;
    if (navigator != null) {
      navigator.popUntil(predicate);
      return;
    }
    Navigator.popUntil(context, predicate);
  }

  @override
  bool canPop(BuildContext context) {
    return GoRouter.of(context).canPop() || Navigator.canPop(context);
  }

  @override
  Future<bool> maybePop<T extends Object?>(BuildContext context, [T? result]) {
    return Navigator.maybePop(context, result);
  }

  @override
  void popAndPushNamed(
    BuildContext context,
    String routeName, {
    Object? arguments,
  }) {
    final router = GoRouter.of(context);
    if (router.canPop()) {
      router.pop();
    }
    final location = _maybeWrapToHybridAppRoute(context, routeName);
    router.push(location, extra: arguments);
  }

  @override
  void pushNamedAndRemoveUntil(
    BuildContext context,
    String newRouteName,
    RoutePredicate predicate, {
    Object? arguments,
  }) {
    final router = GoRouter.of(context);
    final navigator = router.routerDelegate.navigatorKey.currentState;
    final location = _maybeWrapToHybridAppRoute(context, newRouteName);
    if (navigator != null) {
      navigator.popUntil(predicate);
      router.push(location, extra: arguments);
      return;
    }
    router.go(location, extra: arguments);
  }
}

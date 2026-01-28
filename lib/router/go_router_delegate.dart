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
    // If it's already one of our Flutter-native routes, keep it as-is.
    // Otherwise, treat it as a WebF internal route and wrap it into `/app?...&path=...`.
    Uri? targetUri;
    try {
      targetUri = Uri.parse(location);
    } catch (_) {
      return location;
    }

    final path = targetUri.path.isEmpty ? '/' : targetUri.path;
    if (path == kLauncherPath ||
        path == kScannerPath ||
        path == kWebfRoutePath ||
        path == kUseCasesPath ||
        path == kAppRoutePath) {
      return location;
    }

    Uri currentUri;
    try {
      currentUri = GoRouterState.of(context).uri;
    } catch (_) {
      // If we can't read current route context, fall back to raw location.
      return location;
    }

    // Only wrap when we have enough context to build the `/app` URL.
    final url = currentUri.queryParameters[kUrlParam];
    if (url == null || url.isEmpty) {
      return location;
    }

    // WebF hybrid route expects the internal path in query param `path`.
    // We intentionally ignore query/fragment of [location] here; WebF routing
    // state should be passed via the `arguments`/state channel.
    final normalizedPath = path.startsWith('/') ? path : '/$path';
    return buildWebFRouteUrlFromUri(
      uri: currentUri,
      route: kAppRoutePath,
      path: normalizedPath,
    );
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
    if (context == null) return initialRoute ?? '/';
    try {
      return GoRouterState.of(context).uri.toString();
    } catch (_) {
      String? currentPath = ModalRoute.of(context)?.settings.name;
      return currentPath ?? initialRoute ?? '/';
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

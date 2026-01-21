import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart' show useEffect, useState;
import 'package:hooks_riverpod/hooks_riverpod.dart'
    show HookConsumerWidget, WidgetRef;
import 'package:webf/launcher.dart' show WebFController, WebFControllerManager;
import 'package:webf/webf.dart' show WebFBundle;
import 'package:webf/widget.dart' show WebFRouterView;
import '../services/hybrid_controller_manager.dart';
import '../router/app_router.dart' show kGoRouterDelegate, kWebfRouteObserver;
import '../utils/app_logger.dart';
import '../widgets/webf_inspector_overlay.dart';

/// A simple RouteAware implementation for monitoring route lifecycle
class _RouteAwareSubscription extends RouteAware {
  final VoidCallback? onPushed;
  final VoidCallback? onPopped;
  final VoidCallback? onPushedNext;
  final VoidCallback? onPoppedNext;

  _RouteAwareSubscription({
    this.onPushed,
    this.onPopped,
    this.onPushedNext,
    this.onPoppedNext,
  });

  @override
  void didPush() => onPushed?.call();

  @override
  void didPop() => onPopped?.call();

  @override
  void didPushNext() => onPushedNext?.call();

  @override
  void didPopNext() => onPoppedNext?.call();
}

Future<WebFController?> injectWebfBundleAsync({
  required String controllerName,
  required String url,
}) async {
  appLogger.d(
    '[WebFPage] Injecting bundle for controller: $controllerName\n  URL: $url',
  );

  try {
    // 使用 updateWithPrerendering 动态注入/更新 bundle
    // UI 已经通过 fromControllerName 绑定，这里只负责注入内容
    final controller = await WebFControllerManager.instance.addWithPrerendering(
      name: controllerName,
      createController: () => WebFController(routeObserver: kWebfRouteObserver),
      bundle: WebFBundle.fromUrl(url),
      setup: (controller) {
        controller.hybridHistory.delegate = kGoRouterDelegate;
        appLogger.i('[WebFPage] Controller setup complete');
      },
    );

    appLogger.i('[WebFPage] Bundle injection complete');
    return controller;
  } catch (e, stackTrace) {
    appLogger.e(
      '[WebFPage] Failed to inject bundle',
      error: e,
      stackTrace: stackTrace,
    );
    return null;
  }
}

Widget buildStatusView({required String title, required Widget child}) {
  return Scaffold(
    appBar: AppBar(
      title: Text(title, maxLines: 1, overflow: TextOverflow.ellipsis),
    ),
    body: Stack(
      children: [
        Center(child: child),
        const WebFInspectorOverlay(),
      ],
    ),
  );
}

class WebFPage extends HookConsumerWidget {
  const WebFPage({
    super.key,
    required this.url,
    required this.controllerName,
    this.routePath = '/',
    this.title,
  });

  final String url;
  final String controllerName;
  final String routePath;
  final String? title;

  /// Display title for AppBar - uses title if provided, otherwise url
  String get displayTitle => title ?? url;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controllerInstance = useState<WebFController?>(null);
    final initError = useState<Object?>(null);
    final isInitialized = useState(false);
    final isAttached = useState(false);
    final isReady = useState(false);
    final isRouteCurrent = useState(true);
    final routeObserverSubscription = useState<Object?>(null);

    useEffect(() {
      var cancelled = false;
      isInitialized.value = false;
      initError.value = null;

      Future<void> run() async {
        final controller = await injectWebfBundleAsync(
          controllerName: controllerName,
          url: url,
        );
        if (cancelled) return;
        if (!context.mounted) return;
        controllerInstance.value = controller;
        if (controller == null) {
          initError.value = 'Controller initialization returned null';
        } else {
          isInitialized.value = true;
        }
      }

      run();
      return () {
        cancelled = true;
      };
    }, [controllerName, url]);

    // Effect 1: Monitor route focus changes using RouteObserver
    useEffect(() {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!context.mounted) return;

        final route = ModalRoute.of(context);
        if (route == null || route is! PageRoute) return;

        // Create a simple route observer subscription
        final subscription = _RouteAwareSubscription(
          onPushed: () {
            appLogger.d('[WebFPage] Route pushed (gained focus)');
            isRouteCurrent.value = true;
          },
          onPopped: () {
            appLogger.d('[WebFPage] Route popped (lost focus)');
            isRouteCurrent.value = false;
          },
          onPushedNext: () {
            appLogger.d('[WebFPage] Next route pushed (lost focus)');
            isRouteCurrent.value = false;
          },
          onPoppedNext: () {
            appLogger.d('[WebFPage] Next route popped (gained focus)');
            isRouteCurrent.value = true;
          },
        );

        kWebfRouteObserver.subscribe(subscription, route);
        routeObserverSubscription.value = subscription;

        // Check initial route state - if route is already current, trigger immediately
        if (route.isCurrent) {
          appLogger.d('[WebFPage] Route is initially current (gained focus)');
          isRouteCurrent.value = true;
        }
      });

      return () {
        final subscription = routeObserverSubscription.value;
        if (subscription is RouteAware) {
          kWebfRouteObserver.unsubscribe(subscription);
        }
      };
    }, []);

    // Effect 2: Handle attach/detach lifecycle based on route focus
    useEffect(
      () {
        if (!isInitialized.value || !isRouteCurrent.value) {
          return null;
        }
        final controller = controllerInstance.value;
        if (controller == null) {
          return null;
        }

        isAttached.value = false;

        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!context.mounted) return;

          // Intelligently attach: first reference uses manager, subsequent use direct push
          final refCount = HybridControllerManager.instance.attachController(
            controllerName,
            context,
            controller,
          );
          appLogger.d(
            '[WebFPage] ✅ Attached controller (ref count: $refCount)',
          );

          // Mark as attached so route checking can begin
          isAttached.value = true;
        });

        return () {
          isAttached.value = false;

          // Intelligently detach: last reference uses manager, intermediate use direct pop
          final refCount = HybridControllerManager.instance.detachController(
            controllerName,
            context.mounted ? context : null,
            controller,
          );
          appLogger.d(
            '[WebFPage] 🔌 Detached controller (ref count: $refCount)',
          );
        };
      },
      [
        isInitialized.value,
        isRouteCurrent.value,
        controllerInstance.value,
        controllerName,
      ],
    );

    // Effect 3: Check route ready status (only after attached)
    useEffect(() {
      if (!isAttached.value) {
        return null;
      }
      final controller = controllerInstance.value;
      if (controller == null) {
        return null;
      }

      isReady.value = false;
      final startTime = DateTime.now();
      var frameCount = 0;
      var disposed = false;

      void checkRouteReady() {
        if (disposed || !context.mounted) return;

        frameCount++;
        final routerView = controller.view.getHybridRouterView(routePath);
        final elapsed = DateTime.now().difference(startTime).inMilliseconds;

        if (routerView != null) {
          appLogger.i(
            '[WebFPage] 🎉 Route ready after $frameCount frames (${elapsed}ms)',
          );
          isReady.value = true;
        } else if (frameCount >= 10) {
          // Stop after 10 frames (~150-200ms)
          appLogger.w(
            '[WebFPage] ⏰ Route not ready after $frameCount frames (${elapsed}ms)',
          );
          isReady.value = true;
        } else {
          // Schedule next frame check
          appLogger.d(
            '[WebFPage] ⏳ Frame $frameCount: Route pending (${elapsed}ms)',
          );
          WidgetsBinding.instance.addPostFrameCallback(
            (_) => checkRouteReady(),
          );
        }
      }

      // Start checking
      WidgetsBinding.instance.addPostFrameCallback((_) => checkRouteReady());

      return () {
        disposed = true;
      };
    }, [isAttached.value, controllerInstance.value, routePath]);

    appLogger.d(
      '[WebFPage] Building WebFRouterView.fromControllerName:\n  controllerName: $controllerName\n  path: $routePath\n  url: $url',
    );
    if (initError.value != null) {
      appLogger.e('[WebFPage] Init error: ${initError.value}');
    }

    if (!isInitialized.value || !isReady.value) {
      return buildStatusView(
        title: displayTitle,
        child: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Initializing WebF...'),
          ],
        ),
      );
    }

    if (initError.value != null) {
      return buildStatusView(
        title: displayTitle,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.red),
            const SizedBox(height: 16),
            Text(
              'Init failed: ${initError.value ?? 'Unknown error'}',
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    final controller = controllerInstance.value!;
    appLogger.d(
      '[WebFPage] Controller status:\n  hasLoadingError: ${controller.hasLoadingError}\n  loadingError: ${controller.loadingError}\n  isDOMComplete: ${controller.isDOMComplete}\n  preRenderingStatus: ${controller.preRenderingStatus}',
    );

    if (!controller.isDOMComplete) {
      return buildStatusView(
        title: displayTitle,
        child: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Waiting for DOMContentLoaded...'),
          ],
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(displayTitle, maxLines: 1, overflow: TextOverflow.ellipsis),
      ),
      body: Stack(
        children: [
          WebFRouterView(
            controller: controller,
            path: routePath,
            defaultViewBuilder: (context) => Center(
              child: Text(
                'Hybrid route "$routePath" not found yet. Verify webf-router registration or wait for routes to be ready.',
                textAlign: TextAlign.center,
              ),
            ),
          ),
          const WebFInspectorOverlay(),
        ],
      ),
    );
  }
}

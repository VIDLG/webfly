import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:signals_hooks/signals_hooks.dart';
import '../router/app_router.dart' show kWebfRouteObserver;

/// A hook that monitors when the current route gains or loses focus.
///
/// Returns a [Signal]\<bool\> that is true when the route is current/focused,
/// and false when another route is pushed on top or this route is popped.
///
/// This is useful for triggering effects only when a page is visible to the user.
Signal<bool> useRouteFocus() {
  final context = useContext();
  final isRouteCurrent = useSignal(true);
  final routeObserverSubscription = useRef<RouteAware?>(null);

  useEffect(() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!context.mounted) return;

      final route = ModalRoute.of(context);
      if (route == null || route is! PageRoute) return;

      // Create a route observer subscription
      final subscription = _RouteAwareCallback(
        onPushed: () => isRouteCurrent.value = true,
        onPopped: () => isRouteCurrent.value = false,
        onPushedNext: () => isRouteCurrent.value = false,
        onPoppedNext: () => isRouteCurrent.value = true,
      );

      kWebfRouteObserver.subscribe(subscription, route);
      routeObserverSubscription.value = subscription;

      // Check initial route state
      if (route.isCurrent) {
        isRouteCurrent.value = true;
      }
    });

    return () {
      final subscription = routeObserverSubscription.value;
      if (subscription != null) {
        kWebfRouteObserver.unsubscribe(subscription);
      }
    };
  }, []);

  return isRouteCurrent;
}

/// Internal RouteAware implementation for the hook
class _RouteAwareCallback extends RouteAware {
  final VoidCallback? onPushed;
  final VoidCallback? onPopped;
  final VoidCallback? onPushedNext;
  final VoidCallback? onPoppedNext;

  _RouteAwareCallback({
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

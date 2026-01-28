# Hybrid Routing Notes (Historical)

This document describes issues encountered when implementing hybrid routing with go_router and WebF, along with their workarounds.

**Status**: Historical reference. The project has converged to WebF's official widget lifecycle management.

**Current approach (recommended)**

- Render the root document with `WebF.fromControllerName(...)`.
- Render hybrid sub routes with `WebFRouterView.fromControllerName(..., path: ...)`.
- Avoid manual attach/detach stacks and custom reference counting.

The previously-used `HybridControllerManager` workaround was removed.

## Problem 1: Controller Attach/Detach Stack Corruption

### Symptom
When navigating between pages (e.g., Home → Profile → Back), the WebF controller's BuildContext stack becomes corrupted. After pressing the back button, the controller detaches and the stack becomes empty, breaking subsequent navigation.

### Root Cause
**Bug in `WebFControllerManager.attachController()`** (webf 0.24.6):

```dart
Future<void> attachController(
  String name,
  BuildContext? flutterContext,
  WebFController controller,
) async {
  if (_attachedControllers[name] == controller) {
    return; // ❌ Early return prevents pushNewBuildContext!
  }

  _attachedControllers[name] = controller;
  controller.attachToFlutter(flutterContext!);
}
```

The early return when the controller is already attached prevents `controller.attachToFlutter()` from being called. This means `pushNewBuildContext()` never executes, so the BuildContext stack doesn't grow when navigating to a new page.

**Similar bug in `detachController()`**:

```dart
Future<void> detachController(
  String name,
  BuildContext? flutterContext,
  WebFController controller,
) async {
  if (_attachedControllers[name] != controller) {
    return; // ❌ Prevents detachFromFlutter when controller is in map
  }

  _attachedControllers.remove(name);
  controller.detachFromFlutter(flutterContext!);
}
```

### Historical workaround: Hybrid Controller Manager with Reference Counting

Created `HybridControllerManager` that maintains reference counts. Since all pages share the same controller instance, the reference count tracks how many pages are currently using it:

```dart
class HybridControllerManager {
  static final instance = HybridControllerManager._();
  HybridControllerManager._();

  final _referenceCounts = <String, int>{};

  int attachController(
    String name,
    BuildContext context,
    WebFController controller,
  ) {
    final currentCount = _referenceCounts[name] ?? 0;
    final newCount = currentCount + 1;
    _referenceCounts[name] = newCount;

    try {
      if (currentCount == 0) {
        // First reference: register with manager
        WebFControllerManager().attachController(name, context, controller);
      } else {
        // Subsequent references: push context directly
        controller.attachToFlutter(context);
      }
    } catch (e) {
      debugPrint('❌ HybridControllerManager.attachController error: $e');
      rethrow;
    }

    return newCount;
  }

  int detachController(
    String name,
    BuildContext context,
    WebFController controller,
  ) {
    final currentCount = _referenceCounts[name] ?? 0;
    if (currentCount <= 0) {
      debugPrint('⚠️  Attempting to detach with count $currentCount');
      return 0;
    }

    final newCount = currentCount - 1;
    _referenceCounts[name] = newCount;

    try {
      if (newCount == 0) {
        // Last reference: unregister from manager
        WebFControllerManager().detachController(name, context, controller);
      } else {
        // Intermediate references: pop context directly
        controller.detachFromFlutter(context);
      }
    } catch (e) {
      debugPrint('❌ HybridControllerManager.detachController error: $e');
      rethrow;
    }

    return newCount;
  }
}
```

**Key insight**: Since all pages share one controller, the manager's state should only be updated on the first attach (when any page starts using it) and last detach (when no pages are using it). All intermediate navigation should directly manipulate the controller's BuildContext stack.

## Problem 2: Page Buttons Unresponsive After Navigation

### Symptom
After navigating Home → Profile → Back, buttons on the Home page become unresponsive. Clicking them produces no effect.

### Root Cause
When a page loses focus (another page is pushed on top), the WebF controller remains attached to the old page's BuildContext. When the user returns to the page (via back button), the page's `build()` method runs with the same controller state, but the controller needs to be re-attached to respond to user interactions.

The issue is that our attach/detach logic only runs based on widget lifecycle (mount/unmount), not route focus changes.

### Solution: RouteObserver-Based Focus Monitoring

Implemented `RouteAware` to monitor when a page gains/loses focus:

```dart
class _RouteAwareSubscription with RouteAware {
  final VoidCallback onPushed;
  final VoidCallback onPopped;
  final VoidCallback onPushedNext;
  final VoidCallback onPopNext;

  _RouteAwareSubscription({
    required this.onPushed,
    required this.onPopped,
    required this.onPushedNext,
    required this.onPopNext,
  });

  @override
  void didPush() => onPushed();

  @override
  void didPop() => onPopped();

  @override
  void didPushNext() => onPushedNext();

  @override
  void didPopNext() => onPopNext();
}
```

In `WebFPage`, added route focus tracking:

```dart
// Track route focus state
final isRouteCurrent = useState(false);

// Effect 1: Subscribe to route observer
useEffect(() {
  WidgetsBinding.instance.addPostFrameCallback((_) {
    final route = ModalRoute.of(context);
    if (route == null) return;

    // Check initial focus state
    if (route.isCurrent) {
      isRouteCurrent.value = true;
    }

    // Subscribe to focus changes
    final subscription = _RouteAwareSubscription(
      onPushed: () => isRouteCurrent.value = true,
      onPopped: () => isRouteCurrent.value = false,
      onPushedNext: () => isRouteCurrent.value = false,
      onPopNext: () => isRouteCurrent.value = true, // ✅ Critical!
    );

    if (route is PageRoute) {
      kWebfRouteObserver.subscribe(subscription, route);
    }

    routeObserverSubscription.value = subscription;
  });

  return () {
    final sub = routeObserverSubscription.value;
    if (sub != null) {
      kWebfRouteObserver.unsubscribe(sub);
    }
  };
}, []);

// Effect 2: Attach/detach based on both initialization AND focus
useEffect(() {
  if (!isInitialized.value || !isRouteCurrent.value) {
    return null;
  }

  // Only attach when both initialized and route is current
  final refCount = HybridControllerManager.instance.attachController(
    widget.controllerName,
    context,
    controller,
  );
  isAttached.value = true;

  return () {
    if (isAttached.value) {
      HybridControllerManager.instance.detachController(
        widget.controllerName,
        context,
        controller,
      );
      isAttached.value = false;
    }
  };
}, [isInitialized.value, isRouteCurrent.value]);
```

**Key insight**: The `didPopNext()` callback is critical. It fires when returning to a previous page, and that's when we need to set `isRouteCurrent.value = true` to trigger re-attachment.

## Problem 3: WebFRouterLink Reliability Issues

### Symptom
Declarative navigation using `WebFRouterLink` component sometimes fails to work, while imperative `navigate()` calls work consistently.

### Solution: Use Imperative Navigation Everywhere

Replace all `WebFRouterLink` usage with `useNavigate()` hook:

```tsx
// ❌ Before: Declarative (unreliable)
<WebFRouterLink path="/products" title="Products">
  <button>Browse Products</button>
</WebFRouterLink>

// ✅ After: Imperative (reliable)
const { navigate } = useNavigate()
<button onClick={() => navigate('/products')}>
  Browse Products
</button>
```

## Summary

The workarounds address three interconnected issues:

1. **Stack Management**: HybridControllerManager with reference counting ensures the BuildContext stack grows/shrinks correctly
2. **Focus Tracking**: RouteObserver monitors route focus changes to re-attach the controller when returning to a page
3. **Navigation Pattern**: Imperative `navigate()` provides more reliable navigation than declarative `WebFRouterLink`

These solutions enable stable hybrid routing with go_router and WebF, supporting complex navigation patterns like nested stacks, back navigation, and state preservation.

## Implementation Files

- `lib/services/hybrid_controller_manager.dart` - Reference counting manager
- `lib/pages/webf_page.dart` - RouteObserver integration
- TypeScript pages - Imperative navigation with `useNavigate()`

## Versions

- WebF: 0.24.6
- Flutter SDK: (your version)
- go_router: (your version)

## Potential Upstream Fixes

The root cause bugs in `WebFControllerManager` could be fixed by:

1. Removing the early return check in `attachController()` - always call `controller.attachToFlutter()`
2. Adjusting the state check in `detachController()` - allow detach even when controller is in the map

However, reference counting may still be valuable for managing multiple pages sharing the same controller.

---

## Working Code Implementation

### 1. HybridControllerManager (lib/services/hybrid_controller_manager.dart)

Complete reference counting manager for intelligent attach/detach:

```dart
import 'package:flutter/widgets.dart';
import 'package:webf/launcher.dart' show WebFController, WebFControllerManager;

class HybridControllerManager {
  static final HybridControllerManager _instance = HybridControllerManager._internal();
  HybridControllerManager._internal();
  static HybridControllerManager get instance => _instance;

  final Map<String, int> _referenceCounts = {};

  /// Attach controller with reference counting
  /// - First reference (0→1): Uses WebFControllerManager to register
  /// - Subsequent references: Directly pushes context to stack
  int attachController(
    String controllerName,
    BuildContext context,
    WebFController controller,
  ) {
    final currentCount = _referenceCounts[controllerName] ?? 0;
    final newCount = currentCount + 1;
    _referenceCounts[controllerName] = newCount;

    try {
      if (currentCount == 0) {
        // First reference: register with manager
        WebFControllerManager.instance.attachController(controllerName, context);
      } else {
        // Subsequent references: push context directly to bypass early return bug
        controller.attachToFlutter(context);
      }
    } catch (e) {
      debugPrint('❌ HybridControllerManager.attachController error: $e');
      rethrow;
    }

    return newCount;
  }

  /// Detach controller with reference counting
  /// - Last reference (→0): Uses WebFControllerManager to unregister
  /// - Intermediate references: Directly pops context from stack
  int detachController(
    String controllerName,
    BuildContext? context,
    WebFController controller,
  ) {
    try {
      final currentCount = _referenceCounts[controllerName] ?? 0;
      if (currentCount <= 0) {
        // Already at zero, cleanup anyway
        WebFControllerManager.instance.detachController(controllerName, context);
        return 0;
      }

      final newCount = currentCount - 1;
      _referenceCounts[controllerName] = newCount;

      if (newCount == 0) {
        // Last reference: unregister from manager
        WebFControllerManager.instance.detachController(controllerName, context);
      } else {
        // Intermediate references: pop context directly
        controller.detachFromFlutter(context);
      }

      return newCount;
    } catch (e) {
      debugPrint('❌ HybridControllerManager.detachController error: $e');
      return -1;
    }
  }

  int getReferenceCount(String controllerName) {
    return _referenceCounts[controllerName] ?? 0;
  }
}
```

### 2. Route Focus Monitoring (lib/pages/webf_page.dart)

RouteAware implementation for monitoring when pages gain/lose focus:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../services/hybrid_controller_manager.dart';

/// RouteAware subscription for monitoring route lifecycle
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

class WebFPage extends HookConsumerWidget {
  const WebFPage({
    super.key,
    required this.url,
    required this.controllerName,
  });

  final String url;
  final String controllerName;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controllerInstance = useState<WebFController?>(null);
    final isInitialized = useState(false);
    final isAttached = useState(false);
    final isRouteCurrent = useState(true);
    final routeObserverSubscription = useState<RouteAware?>(null);

    // Effect 1: Initialize controller
    useEffect(() {
      var cancelled = false;
      isInitialized.value = false;

      Future<void> run() async {
        // Use WebFControllerManager to create/get controller
        final controller = await WebFControllerManager.instance.addWithPrerendering(
          name: controllerName,
          createController: () => WebFController(routeObserver: kWebfRouteObserver),
          bundle: WebFBundle.fromUrl(url),
          setup: (controller) {
            controller.hybridHistory.delegate = kGoRouterDelegate;
          },
        );

        if (cancelled) return;
        if (!context.mounted) return;

        controllerInstance.value = controller;
        isInitialized.value = true;
      }

      run();
      return () {
        cancelled = true;
      };
    }, [controllerName, url]);

    // Effect 2: Monitor route focus changes using RouteObserver
    useEffect(() {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!context.mounted) return;

        final route = ModalRoute.of(context);
        if (route == null || route is! PageRoute) return;

        final subscription = _RouteAwareSubscription(
          onPushed: () {
            debugPrint('[WebFPage] Route gained focus (pushed)');
            isRouteCurrent.value = true;
          },
          onPopped: () {
            debugPrint('[WebFPage] Route lost focus (popped)');
            isRouteCurrent.value = false;
          },
          onPushedNext: () {
            debugPrint('[WebFPage] Route lost focus (next pushed)');
            isRouteCurrent.value = false;
          },
          onPoppedNext: () {
            debugPrint('[WebFPage] Route gained focus (next popped)');
            isRouteCurrent.value = true; // ✅ Critical for re-attachment!
          },
        );

        kWebfRouteObserver.subscribe(subscription, route);
        routeObserverSubscription.value = subscription;

        // Check if route is already current on mount
        if (route.isCurrent) {
          debugPrint('[WebFPage] Route is initially current');
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

    // Effect 3: Attach/detach based on initialization AND route focus
    useEffect(() {
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

        // Intelligently attach using reference counting
        final refCount = HybridControllerManager.instance.attachController(
          controllerName,
          context,
          controller,
        );
        isAttached.value = true;
        debugPrint('[WebFPage] Attached (refCount: $refCount)');
      });

      return () {
        if (!isAttached.value) return;

        // Intelligently detach using reference counting
        final refCount = HybridControllerManager.instance.detachController(
          controllerName,
          context,
          controller,
        );
        isAttached.value = false;
        debugPrint('[WebFPage] Detached (refCount: $refCount)');
      };
    }, [isInitialized.value, isRouteCurrent.value]);

    // Return your WebF widget here
    return WebFRouterView.fromControllerName(
      controllerName: controllerName,
      // ... other properties
    );
  }
}
```

### 3. Imperative Navigation (TypeScript)

Replace declarative `WebFRouterLink` with imperative `navigate()`:

```tsx
import { useNavigate } from '@openwebf/react-router'

function HomePage() {
  const { navigate } = useNavigate()

  return (
    <div>
      <h1>Home Page</h1>

      {/* ❌ Avoid: WebFRouterLink can be unreliable */}
      {/* <WebFRouterLink path="/profile">
        <button>Go to Profile</button>
      </WebFRouterLink> */}

      {/* ✅ Use: Imperative navigate() is more stable */}
      <button onClick={() => navigate('/profile', { state: { from: 'home' } })}>
        Go to Profile
      </button>

      <button onClick={() => navigate('/products')}>
        View Products
      </button>
    </div>
  )
}

export default HomePage
```

### 4. Router Setup with RouteObserver

Register the global `RouteObserver` in your router configuration:

```dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

// Global RouteObserver for WebF pages
final RouteObserver<ModalRoute> kWebfRouteObserver = RouteObserver<ModalRoute>();

final GoRouter appRouter = GoRouter(
  observers: [kWebfRouteObserver], // ✅ Register the observer
  routes: [
    GoRoute(
      path: '/',
      builder: (context, state) => const WebFPage(
        url: 'http://localhost:5173/',
        controllerName: 'main',
      ),
    ),
    GoRoute(
      path: '/profile',
      builder: (context, state) => const WebFPage(
        url: 'http://localhost:5173/profile',
        controllerName: 'main', // ✅ All routes must use the same controller name
      ),
    ),
    // ... more routes (all must share the same controllerName)
  ],
);
```

## Key Points

1. **Reference Counting**: First attach uses manager (registers controller), subsequent attaches push context directly. Last detach uses manager (unregisters), intermediate detaches pop context directly.

2. **Route Focus**: `didPopNext()` callback is critical - it fires when returning to a previous page, triggering re-attachment so buttons become responsive again.

3. **Imperative Navigation**: Use `navigate()` function instead of `WebFRouterLink` component for reliability.

4. **RouteObserver**: Must be registered in `GoRouter` observers list for route lifecycle monitoring to work.

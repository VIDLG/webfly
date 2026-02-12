# HybridRouterChangeEvent bypasses HybridHistoryDelegate.state() — uses ModalRoute.settings.arguments directly

## Summary

In `WebFRouterViewState`, the `RouteAware` callbacks (`didPush`, `didPop`, etc.) read state from `ModalRoute.of(context).settings.arguments` and dispatch it via `HybridRouterChangeEvent`. This bypasses the `HybridHistoryDelegate.state()` override entirely.

Since the JS-side `@openwebf/react-router` prioritizes the event-driven path over the synchronous `webf.hybridHistory.state` getter, the delegate's `state()` method effectively has no influence on what `useLocation().state` returns.

## Reproduction

1. Implement a custom `HybridHistoryDelegate` that overrides `state()` to return custom data
2. Navigate to a WebF page
3. In JS, read `useLocation().state` — it contains `ModalRoute.settings.arguments` (e.g. GoRouter's URL query params), **not** the value returned by `delegate.state()`

## Root Cause

In `router_view.dart`, the `RouteAware` callbacks read state directly from Flutter's `ModalRoute`:

```dart
void didPush() {
    ModalRoute route = ModalRoute.of(context)!;
    var state = route.settings.arguments;  // bypasses delegate
    String path = widget.path;
    dom.Event event = HybridRouterChangeEvent(
        state: state, kind: 'didPush', path: path);
    widget.controller.view.document.dispatchEvent(event);
}
```

Meanwhile, JS `useLocation()` prioritizes this event state:

```js
// @openwebf/react-router
const state = context.isActive
    ? (context.params || WebFRouter.state)  // context.params from event takes priority
    : WebFRouter.state;                      // delegate.state() only used as fallback
```

So there are two divergent paths delivering state to JS:

| Path | Source | Priority |
|------|--------|----------|
| Event-driven | `ModalRoute.of(context).settings.arguments` | **High** (used by `useLocation().state`) |
| Synchronous | `HybridHistoryDelegate.state()` | Low (fallback only) |

With GoRouter, `ModalRoute.settings.arguments` contains the URL query parameters map (e.g. `{url: "...", ctrl: "...", loc: "..."}`), while `delegate.state()` returns `GoRouterState.extra`. These are different values, causing an inconsistency.

## Expected Behavior

The event-driven path should respect the `HybridHistoryDelegate.state()` override when a delegate is set, so that both paths return consistent data.

## Suggested Fix

In `WebFRouterViewState`, when `hybridHistory.delegate` is set, use it to resolve state:

```dart
void didPush() {
    final delegate = widget.controller.hybridHistory.delegate;
    final state = delegate != null
        ? delegate.state(context, null)
        : ModalRoute.of(context)?.settings.arguments;

    String path = widget.path;
    dom.Event event = HybridRouterChangeEvent(
        state: state, kind: 'didPush', path: path);
    widget.controller.view.document.dispatchEvent(event);
}
```

This applies to `didPop`, `didPushNext`, and `didPopNext` as well.

## Workaround

Encode all state data into URL query parameters so that `ModalRoute.settings.arguments` naturally contains the intended state — avoiding reliance on `delegate.state()`.

## Environment

- WebF: 0.24.11
- `@openwebf/react-router`: 0.24.x
- GoRouter: 14.x

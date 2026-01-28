# Bug: RenderFlowLayout mutated during RootRenderViewportBox.performLayout (WebF 0.24.8)

## Summary
When loading a WebF page (via `WebF.fromControllerName(...)` / `AutoManagedWebF`), Flutter throws a debug assertion during layout:

> A RenderFlowLayout was mutated in RootRenderViewportBox.performLayout.
> A RenderObject must not mutate its descendants in its performLayout method.

This appears to happen because `RenderViewportBox.size=` triggers `controller.view.notifyViewportSizeChanged()` during layout, which (synchronously) triggers `window.resizeViewportRelatedElements()` and ends up calling `RenderStyle.markNeedsLayout()` on descendants while the layout phase is running.

## Affected version
- `webf: 0.24.8`

## Platform
- Flutter: 3.38.7 (from local environment)
- OS: Windows (host), Android device (runtime)

## Expected
WebF should not invalidate/mutate descendant layout during a `RenderObject.performLayout()` call. Layout mutation should be deferred to a post-frame callback or otherwise scheduled outside the current layout phase.

## Actual
Flutter throws an assertion during layout and the page fails to render correctly (black screen / stuck).

## Logs / Stack trace
```
I/flutter ( 4043): WebF: loading with controller: WebFController#c01a6 (disposed: false, evaluated: true, status: PreRenderingStatus.done)
I/flutter ( 4043): WebF: start for loading http://192.168.2.246:5173..

══╡ EXCEPTION CAUGHT BY RENDERING LIBRARY ╞═════════════════════════════════════════════════════════
The following assertion was thrown during performLayout():
A RenderFlowLayout was mutated in RootRenderViewportBox.performLayout.
A RenderObject must not mutate its descendants in its performLayout method.
...
The relevant error-causing widget was:
  WebFRootViewport
  webf.dart:571:12

#0      RenderObject._debugCanPerformMutations.<anonymous closure> (package:flutter/src/rendering/object.dart:2272:7)
#1      RenderObject._debugCanPerformMutations (package:flutter/src/rendering/object.dart:2296:6)
#2      RenderObject.markNeedsLayout (package:flutter/src/rendering/object.dart:2529:12)
#3      RenderBox.markNeedsLayout (package:flutter/src/rendering/box.dart:2859:11)
#4      RenderStyle.markNeedsLayout.<anonymous closure> (package:webf/src/css/render_style.dart:934:20)
#5      RenderStyle.everyAttachedWidgetRenderBox (package:webf/src/css/render_style.dart:1236:35)
#6      RenderStyle.markNeedsLayout (package:webf/src/css/render_style.dart:933:5)
#7      Window.resizeViewportRelatedElements (package:webf/src/dom/window.dart:124:27)
#8      WebFViewController.notifyViewportSizeChanged (package:webf/src/launcher/view_controller.dart:482:14)
#9      RenderViewportBox.size= (package:webf/src/rendering/viewport.dart:71:23)
#10     RenderViewportBox.performLayout (package:webf/src/rendering/viewport.dart:93:9)
...
```

## Minimal reproduction idea
A minimal reproduction likely only needs:

1. A Flutter app embedding WebF using `WebF.fromControllerName(controllerName: ..., initialRoute: '/')` (or the equivalent `AutoManagedWebF`).
2. Any page that causes viewport-related style recalculation (the crash happens immediately for us, even at first render).

## Root cause hypothesis
From the stack trace, the critical path is:

- `RenderViewportBox.performLayout()` sets `size`
- `RenderViewportBox.size=` calls `controller.view.notifyViewportSizeChanged()` immediately
- `notifyViewportSizeChanged()` calls `window.resizeViewportRelatedElements()`
- which calls into CSS/render tree and triggers `RenderStyle.markNeedsLayout()` on descendants
- this violates Flutter’s rule: no descendant mutation during `performLayout()`

## Suggested fix
Defer the `notifyViewportSizeChanged()` effects to after the current frame/layout, e.g.:

- schedule via `SchedulerBinding.instance.addPostFrameCallback` (debounced) when size changes
- or queue internal resize work and flush outside layout

This should preserve correctness and avoid triggering `RenderObject._debugCanPerformMutations`.

## Additional context
We initially hit this while troubleshooting black screens during navigation in a hybrid routing setup. The crash happens even when using WebF’s official widgets, without custom controller attach/detach hacks.

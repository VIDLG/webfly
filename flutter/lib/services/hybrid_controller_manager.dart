import 'package:flutter/widgets.dart';
import 'package:webf/launcher.dart' show WebFController, WebFControllerManager;

/// Manages WebF controller attachment/detachment in hybrid routing scenarios.
///
/// In hybrid routing, multiple pages can share the same controller, and each page
/// needs to push/pop its context from the controller's context stack. This manager
/// maintains reference counts and intelligently chooses between manager-level or
/// direct controller operations to ensure correct state management and context stack
/// balance.
class HybridControllerManager {
  static final HybridControllerManager _instance =
      HybridControllerManager._internal();

  HybridControllerManager._internal();

  static HybridControllerManager get instance => _instance;

  // Map of controller name to reference count
  final Map<String, int> _referenceCounts = {};

  /// Intelligently attaches a controller based on reference count.
  ///
  /// - First reference (0→1): Uses WebFControllerManager.attachController() to
  ///   update manager state and attach to Flutter.
  /// - Subsequent references (>1): Uses controller.attachToFlutter() directly to
  ///   push new context to stack, bypassing manager's early return bug.
  ///
  /// Returns the new reference count after incrementing.
  int attachController(
    String controllerName,
    BuildContext context,
    WebFController controller,
  ) {
    final currentCount = _referenceCounts[controllerName] ?? 0;
    final newCount = currentCount + 1;
    _referenceCounts[controllerName] = newCount;

    if (currentCount == 0) {
      // First reference: use manager to update state
      WebFControllerManager.instance.attachController(controllerName, context);
    } else {
      // Subsequent reference: directly push context to stack
      controller.attachToFlutter(context);
    }

    return newCount;
  }

  /// Intelligently detaches a controller based on reference count.
  ///
  /// - Last reference (→0): Uses WebFControllerManager.detachController() to
  ///   update manager state and pop context from stack.
  /// - Intermediate references (>0): Uses controller.detachFromFlutter() directly
  ///   to pop context from stack only, without updating manager state.
  ///
  /// Returns the new reference count after decrementing, or -1 if an error occurred.
  int detachController(
    String controllerName,
    BuildContext? context,
    WebFController controller,
  ) {
    try {
      final currentCount = _referenceCounts[controllerName] ?? 0;
      if (currentCount <= 0) {
        // Already at zero, use manager anyway to ensure cleanup
        WebFControllerManager.instance.detachController(
          controllerName,
          context,
        );
        return 0;
      }

      final newCount = currentCount - 1;
      _referenceCounts[controllerName] = newCount;

      if (newCount == 0) {
        // Last reference: use manager to update state
        WebFControllerManager.instance.detachController(
          controllerName,
          context,
        );
      } else {
        // Intermediate reference: directly pop context from stack
        controller.detachFromFlutter(context);
      }

      return newCount;
    } catch (e) {
      // Silently handle detach errors to prevent cleanup failures
      return -1;
    }
  }

  /// Gets the current reference count for a controller.
  int getReferenceCount(String controllerName) {
    return _referenceCounts[controllerName] ?? 0;
  }

  /// Clears all reference counts (for testing or reset scenarios).
  void clear() {
    _referenceCounts.clear();
  }
}

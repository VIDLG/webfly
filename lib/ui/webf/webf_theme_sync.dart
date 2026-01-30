import 'package:flutter/material.dart';
import 'package:webf/launcher.dart' show WebFController;
import '../../utils/app_logger.dart';

/// Syncs Flutter theme state to WebF using darkModeOverride
/// Following WebF official recommendation: https://openwebf.com/en/docs/add-webf-to-flutter/advanced-topics/theming
/// 
/// When themeMode is ThemeMode.system, WebF automatically syncs with system theme.
/// When themeMode is light/dark, we use darkModeOverride to override the automatic behavior.
/// 
/// WebF automatically updates the prefers-color-scheme media query.
/// JavaScript can listen to changes using the standard MediaQuery API:
/// ```javascript
/// window.matchMedia('(prefers-color-scheme: dark)').addEventListener('change', (e) => {
///   // Handle theme change
/// });
/// ```
void syncThemeToWebF(WebFController controller, ThemeMode themeMode) {
  try {
    // WebF automatically syncs with system theme when themeMode is ThemeMode.system
    // We only need to set darkModeOverride when user explicitly chooses light or dark
    switch (themeMode) {
      case ThemeMode.light:
        controller.darkModeOverride = false;
        appLogger.d('[WebFThemeSync] Set darkModeOverride=false (light mode)');
        break;
      case ThemeMode.dark:
        controller.darkModeOverride = true;
        appLogger.d('[WebFThemeSync] Set darkModeOverride=true (dark mode)');
        break;
      case ThemeMode.system:
        // Clear override to let WebF automatically sync with system theme
        controller.darkModeOverride = null;
        appLogger.d('[WebFThemeSync] Cleared darkModeOverride (system mode - auto sync)');
        break;
    }
    // WebF automatically dispatches 'colorschemchange' event and updates prefers-color-scheme
    // No need to manually dispatch CustomEvent - WebF handles it automatically
  } catch (e) {
    appLogger.d('[WebFThemeSync] Error syncing theme: $e');
  }
}

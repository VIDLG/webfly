import 'package:flutter/material.dart' show ThemeMode;
import 'package:flutter/widgets.dart' show Brightness, WidgetsBinding;
import 'package:webf/webf.dart' show WebFBaseModule;

import '../store/app_settings.dart';
import '../utils/app_logger.dart';
import 'protocol.dart';

/// WebF Native Module for app settings.
/// Allows JavaScript to update app settings directly via webf.invokeModule.
///
/// Usage in JavaScript:
/// ```javascript
/// // Get current theme
/// const theme = await webf.invokeModule('AppSettings', 'getTheme');
/// // Returns: 'light' | 'dark' | 'system'
///
/// // Set theme
/// await webf.invokeModule('AppSettings', 'setTheme', ['light']);
/// await webf.invokeModule('AppSettings', 'setTheme', ['dark']);
/// await webf.invokeModule('AppSettings', 'setTheme', ['system']);
/// ```
class AppSettingsModule extends WebFBaseModule {
  AppSettingsModule(super.manager);

  @override
  String get name => 'AppSettings';

  @override
  Future<void> initialize() async {
    // Theme sync: Flutter sets darkModeOverride on WebFController; WebF updates
    // prefers-color-scheme and dispatches 'colorschemchange' (see OpenWebF theming docs).
  }

  @override
  Future<dynamic> invoke(String method, List<dynamic> arguments) async {
    if (method == 'setTheme') {
      if (arguments.isEmpty) {
        appLogger.w('[AppSettingsModule] setTheme requires a theme argument');
        return returnErr('setTheme requires a theme argument', code: -32602);
      }
      final theme = arguments[0] as String;
      final ok = await _setTheme(theme);
      return returnOk(ok);
    } else if (method == 'getTheme') {
      return returnOk(_getTheme());
    } else if (method == 'getSystemTheme') {
      return returnOk(_getSystemTheme());
    } else {
      appLogger.w('[AppSettingsModule] Unknown method: $method');
      return returnErr('Unknown method: $method', code: -32601);
    }
  }

  /// Gets current platform (system) theme.
  ///
  /// Returns: 'light' | 'dark'
  String _getSystemTheme() {
    try {
      final brightness =
          WidgetsBinding.instance.platformDispatcher.platformBrightness;
      return brightness == Brightness.dark ? 'dark' : 'light';
    } catch (e) {
      appLogger.w('[AppSettingsModule] Failed to get system theme: $e');
      return 'light';
    }
  }

  /// Gets the current theme preference
  ///
  /// Returns: 'light' | 'dark' | 'system'
  String _getTheme() {
    final themeMode = themeModeSignal.value;
    switch (themeMode) {
      case ThemeMode.light:
        return 'light';
      case ThemeMode.dark:
        return 'dark';
      case ThemeMode.system:
        return 'system';
    }
  }

  /// Sets the theme preference from WebF JavaScript
  ///
  /// Parameters:
  /// - theme: 'light' | 'dark' | 'system'
  ///
  /// Returns: true if successful
  Future<bool> _setTheme(String theme) async {
    try {
      ThemeMode newThemeMode;
      switch (theme.toLowerCase()) {
        case 'light':
          newThemeMode = ThemeMode.light;
          break;
        case 'dark':
          newThemeMode = ThemeMode.dark;
          break;
        case 'system':
          newThemeMode = ThemeMode.system;
          break;
        default:
          appLogger.w('[AppSettingsModule] Invalid theme: $theme');
          return false;
      }

      if (themeModeSignal.value != newThemeMode) {
        themeModeSignal.value = newThemeMode;
        return true;
      }
      return true; // Already set to this theme
    } catch (e) {
      appLogger.e('[AppSettingsModule] Error setting theme: $e');
      return false;
    }
  }

  @override
  void dispose() {
    // No cleanup needed
  }
}

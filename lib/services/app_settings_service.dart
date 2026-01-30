import 'package:flutter/material.dart' show ThemeMode;
import 'package:flutter/widgets.dart' show Brightness, WidgetsBinding;
import 'package:signals_flutter/signals_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart'
    show SharedPreferences;
import 'package:webf/webf.dart' show WebFBaseModule;
import '../utils/app_logger.dart';

class AppSettingsStorage {
  static const _showInspectorKey = 'show_webf_inspector';
  static const _cacheControllersKey = 'cache_controllers';
  static const _themeModeKey = 'theme_mode';

  final SharedPreferences _prefs;

  AppSettingsStorage._(this._prefs);

  static Future<AppSettingsStorage> create() async {
    final prefs = await SharedPreferences.getInstance();
    return AppSettingsStorage._(prefs);
  }

  bool getShowWebfInspector() => _prefs.getBool(_showInspectorKey) ?? false;
  bool getCacheControllers() => _prefs.getBool(_cacheControllersKey) ?? false;
  ThemeMode getThemeMode() {
    final index = _prefs.getInt(_themeModeKey) ?? 0;
    if (index < 0 || index >= ThemeMode.values.length) {
      return ThemeMode.system;
    }
    return ThemeMode.values[index];
  }

  Future<void> setShowWebfInspector(bool value) =>
      _prefs.setBool(_showInspectorKey, value);
  Future<void> setCacheControllers(bool value) =>
      _prefs.setBool(_cacheControllersKey, value);
  Future<void> setThemeMode(ThemeMode value) =>
      _prefs.setInt(_themeModeKey, value.index);
}

// Atomic signals for each setting
final showWebfInspectorSignal = signal<bool>(false);
final cacheControllersSignal = signal<bool>(false);
final themeModeSignal = signal<ThemeMode>(ThemeMode.system);

// Storage instance (initialized once)
AppSettingsStorage? _storage;

// Initialize app settings from storage and setup auto-save
Future<void> initializeAppSettings() async {
  try {
    _storage = await AppSettingsStorage.create();
  } catch (_) {
    _storage = null;
  }

  // Load initial settings without triggering effects
  untracked(() {
    showWebfInspectorSignal.value = _storage?.getShowWebfInspector() ?? false;
    cacheControllersSignal.value = _storage?.getCacheControllers() ?? false;
    themeModeSignal.value = _storage?.getThemeMode() ?? ThemeMode.system;
  });

  // Setup auto-save effects for each setting
  effect(() {
    final storage = _storage;
    if (storage == null) return;
    try {
      storage
          .setShowWebfInspector(showWebfInspectorSignal.value)
          .catchError((_) {});
    } catch (_) {}
  });

  effect(() {
    final storage = _storage;
    if (storage == null) return;
    try {
      storage
          .setCacheControllers(cacheControllersSignal.value)
          .catchError((_) {});
    } catch (_) {}
  });

  effect(() {
    final storage = _storage;
    if (storage == null) return;
    try {
      storage.setThemeMode(themeModeSignal.value).catchError((_) {});
    } catch (_) {}
  });
}

// Direct signal access - no need for convenience methods
// Usage: showWebfInspectorSignal.value = true;

/// WebF Native Module for app settings
/// Allows JavaScript to update app settings directly via webf.invokeModule
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
  Future<dynamic> invoke(String method, List<dynamic> arguments) async {
    if (method == 'setTheme') {
      if (arguments.isEmpty) {
        appLogger.w('[AppSettingsModule] setTheme requires a theme argument');
        return false;
      }
      final theme = arguments[0] as String;
      return await _setTheme(theme);
    } else if (method == 'getTheme') {
      return _getTheme();
    } else if (method == 'getSystemTheme') {
      return _getSystemTheme();
    } else {
      appLogger.w('[AppSettingsModule] Unknown method: $method');
      return false;
    }
  }

  /// Gets current platform (system) theme.
  ///
  /// Returns: 'light' | 'dark'
  String _getSystemTheme() {
    try {
      final brightness = WidgetsBinding.instance.platformDispatcher.platformBrightness;
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
        appLogger.d('[AppSettingsModule] Theme changed from WebF: $theme');
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

import 'package:flutter/material.dart' show ThemeMode;
import 'package:signals_flutter/signals_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart'
    show SharedPreferences;

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
  _storage = await AppSettingsStorage.create();

  // Load initial settings without triggering effects
  untracked(() {
    showWebfInspectorSignal.value = _storage!.getShowWebfInspector();
    cacheControllersSignal.value = _storage!.getCacheControllers();
    themeModeSignal.value = _storage!.getThemeMode();
  });

  // Setup auto-save effects for each setting
  effect(() {
    _storage?.setShowWebfInspector(showWebfInspectorSignal.value);
  });

  effect(() {
    _storage?.setCacheControllers(cacheControllersSignal.value);
  });

  effect(() {
    _storage?.setThemeMode(themeModeSignal.value);
  });
}

// Direct signal access - no need for convenience methods
// Usage: showWebfInspectorSignal.value = true;

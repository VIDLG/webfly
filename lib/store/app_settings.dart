import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:signals_flutter/signals_flutter.dart';

/// App settings store: persistence (SharedPreferences) + reactive signals.
/// Owns both storage and state; auto-saves when signals change.
class AppSettings {
  static const _showInspectorKey = 'show_webf_inspector';
  static const _cacheControllersKey = 'cache_controllers';
  static const _themeModeKey = 'theme_mode';

  final SharedPreferences _prefs;

  final showWebfInspector = signal<bool>(false);
  final cacheControllers = signal<bool>(false);
  final themeMode = signal<ThemeMode>(ThemeMode.system);

  AppSettings._(this._prefs);

  static Future<AppSettings> create() async {
    final prefs = await SharedPreferences.getInstance();
    final store = AppSettings._(prefs);

    untracked(() {
      store.showWebfInspector.value = prefs.getBool(_showInspectorKey) ?? false;
      store.cacheControllers.value =
          prefs.getBool(_cacheControllersKey) ?? false;
      final index = prefs.getInt(_themeModeKey) ?? 0;
      if (index >= 0 && index < ThemeMode.values.length) {
        store.themeMode.value = ThemeMode.values[index];
      }
    });

    effect(() {
      store._prefs
          .setBool(_showInspectorKey, store.showWebfInspector.value)
          .catchError((_) => false);
    });
    effect(() {
      store._prefs
          .setBool(_cacheControllersKey, store.cacheControllers.value)
          .catchError((_) => false);
    });
    effect(() {
      store._prefs
          .setInt(_themeModeKey, store.themeMode.value.index)
          .catchError((_) => false);
    });

    return store;
  }
}

// ---------------------------------------------------------------------------
// Singleton + public API (replaces app_settings_service)
// ---------------------------------------------------------------------------

AppSettings? _store;

Signal<bool> get showWebfInspectorSignal => _store!.showWebfInspector;
Signal<bool> get cacheControllersSignal => _store!.cacheControllers;
Signal<ThemeMode> get themeModeSignal => _store!.themeMode;

/// Initialize app settings (load from disk, setup auto-save).
Future<void> initializeAppSettings() async {
  try {
    _store = await AppSettings.create();
  } catch (_) {
    _store = null;
  }
}

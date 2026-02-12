import 'package:shared_preferences/shared_preferences.dart';
import 'package:signals_flutter/signals_flutter.dart';

/// App settings store: persistence (SharedPreferences) + reactive signals.
/// Theme is in package webfly_theme (getTheme, setTheme, themeStream).
class AppSettings {
  static const _showInspectorKey = 'show_webf_inspector';
  static const _cacheControllersKey = 'cache_controllers';

  final SharedPreferences _prefs;

  final showWebfInspector = signal<bool>(false);
  final cacheControllers = signal<bool>(false);

  AppSettings._(this._prefs);

  static Future<AppSettings> create() async {
    final prefs = await SharedPreferences.getInstance();
    final store = AppSettings._(prefs);

    untracked(() {
      store.showWebfInspector.value = prefs.getBool(_showInspectorKey) ?? false;
      store.cacheControllers.value =
          prefs.getBool(_cacheControllersKey) ?? false;
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

    return store;
  }
}

// ---------------------------------------------------------------------------
// Singleton + public API
// ---------------------------------------------------------------------------

AppSettings? _store;

Signal<bool> get showWebfInspectorSignal => _store!.showWebfInspector;
Signal<bool> get cacheControllersSignal => _store!.cacheControllers;

/// Initialize app settings (load from disk, setup auto-save).
Future<void> initializeAppSettings() async {
  try {
    _store = await AppSettings.create();
  } catch (_) {
    _store = null;
  }
}

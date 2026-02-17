import 'package:shared_preferences/shared_preferences.dart';
import 'package:signals_flutter/signals_flutter.dart';
import 'package:webfly_updater/webfly_updater.dart';

class AppSettings {
  static const _showInspectorKey = 'show_webf_inspector';
  static const _cacheControllersKey = 'cache_controllers';
  static const _updateTestModeKey = 'update_test_mode';
  static const _connectTimeoutKey = 'connect_timeout_seconds';
  static const _receiveTimeoutKey = 'receive_timeout_seconds';
  static const _useExternalBrowserKey = 'use_external_browser';

  final SharedPreferences _prefs;

  final showWebfInspector = signal<bool>(false);
  final cacheControllers = signal<bool>(false);
  final updateTestMode = signal<bool>(false);
  final connectTimeoutSeconds = signal<int>(10);
  final receiveTimeoutSeconds = signal<int>(30);
  final useExternalBrowser = signal<bool>(false);

  AppSettings._(this._prefs);

  static Future<AppSettings> create() async {
    final prefs = await SharedPreferences.getInstance();
    final store = AppSettings._(prefs);

    untracked(() {
      store.showWebfInspector.value = prefs.getBool(_showInspectorKey) ?? false;
      store.cacheControllers.value =
          prefs.getBool(_cacheControllersKey) ?? false;
      store.updateTestMode.value = prefs.getBool(_updateTestModeKey) ?? false;
      store.connectTimeoutSeconds.value =
          prefs.getInt(_connectTimeoutKey) ?? 10;
      store.receiveTimeoutSeconds.value =
          prefs.getInt(_receiveTimeoutKey) ?? 30;
      store.useExternalBrowser.value =
          prefs.getBool(_useExternalBrowserKey) ?? false;
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
          .setBool(_updateTestModeKey, store.updateTestMode.value)
          .catchError((_) => false);
    });
    effect(() {
      store._prefs
          .setInt(_connectTimeoutKey, store.connectTimeoutSeconds.value)
          .catchError((_) => false);
    });
    effect(() {
      store._prefs
          .setInt(_receiveTimeoutKey, store.receiveTimeoutSeconds.value)
          .catchError((_) => false);
    });
    effect(() {
      store._prefs
          .setBool(_useExternalBrowserKey, store.useExternalBrowser.value)
          .catchError((_) => false);
    });

    return store;
  }

  NetworkConfig get networkConfig => NetworkConfig(
    connectTimeout: Duration(seconds: connectTimeoutSeconds.value),
    receiveTimeout: Duration(seconds: receiveTimeoutSeconds.value),
  );
}

// ---------------------------------------------------------------------------
// Singleton + public API
// ---------------------------------------------------------------------------

AppSettings? _store;

Signal<bool> get showWebfInspectorSignal => _store!.showWebfInspector;
Signal<bool> get cacheControllersSignal => _store!.cacheControllers;
Signal<bool> get updateTestModeSignal => _store!.updateTestMode;
Signal<int> get connectTimeoutSignal => _store!.connectTimeoutSeconds;
Signal<int> get receiveTimeoutSignal => _store!.receiveTimeoutSeconds;
Signal<bool> get useExternalBrowserSignal => _store!.useExternalBrowser;
NetworkConfig get networkConfig => _store!.networkConfig;

/// Initialize app settings (load from disk, setup auto-save).
Future<void> initializeAppSettings() async {
  try {
    _store = await AppSettings.create();
  } catch (_) {
    _store = null;
  }
}

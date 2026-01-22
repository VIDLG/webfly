import 'package:flutter/material.dart' show ThemeMode;
import 'package:hooks_riverpod/hooks_riverpod.dart'
    show AsyncNotifier, AsyncNotifierProvider, AsyncValue, Provider;
import 'package:shared_preferences/shared_preferences.dart'
    show SharedPreferences;

/// App settings data class
class AppSettings {
  final bool showWebfInspector;
  final bool cacheControllers;
  final ThemeMode themeMode;

  const AppSettings({
    required this.showWebfInspector,
    required this.cacheControllers,
    required this.themeMode,
  });

  AppSettings copyWith({
    bool? showWebfInspector,
    bool? cacheControllers,
    ThemeMode? themeMode,
  }) {
    return AppSettings(
      showWebfInspector: showWebfInspector ?? this.showWebfInspector,
      cacheControllers: cacheControllers ?? this.cacheControllers,
      themeMode: themeMode ?? this.themeMode,
    );
  }
}

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

  AppSettings loadSettings() {
    final themeModeIndex = _prefs.getInt(_themeModeKey) ?? 0;
    return AppSettings(
      showWebfInspector: _prefs.getBool(_showInspectorKey) ?? false,
      cacheControllers: _prefs.getBool(_cacheControllersKey) ?? false,
      themeMode: ThemeMode.values[themeModeIndex],
    );
  }

  Future<void> saveSettings(AppSettings settings) async {
    await Future.wait([
      _prefs.setBool(_showInspectorKey, settings.showWebfInspector),
      _prefs.setBool(_cacheControllersKey, settings.cacheControllers),
      _prefs.setInt(_themeModeKey, settings.themeMode.index),
    ]);
  }
}

// Unified App Settings Provider
class AppSettingsNotifier extends AsyncNotifier<AppSettings> {
  final Future<AppSettingsStorage> _storageFuture = AppSettingsStorage.create();
  AppSettingsStorage? _storage;

  @override
  Future<AppSettings> build() async {
    final storage = await _ensureStorage();
    return storage.loadSettings();
  }

  Future<AppSettingsStorage> _ensureStorage() async {
    final cached = _storage;
    if (cached != null) {
      return cached;
    }
    final storage = await _storageFuture;
    _storage = storage;
    return storage;
  }

  Future<void> updateSettings(AppSettings settings) async {
    final storage = await _ensureStorage();
    await storage.saveSettings(settings);
    state = AsyncValue.data(settings);
  }

  Future<void> setShowWebfInspector(bool value) async {
    final current = state.value;
    if (current == null) return;
    await updateSettings(current.copyWith(showWebfInspector: value));
  }

  Future<void> setCacheControllers(bool value) async {
    final current = state.value;
    if (current == null) return;
    await updateSettings(current.copyWith(cacheControllers: value));
  }

  Future<void> setThemeMode(ThemeMode value) async {
    final current = state.value;
    if (current == null) return;
    await updateSettings(current.copyWith(themeMode: value));
  }
}

final appSettingsProvider =
    AsyncNotifierProvider<AppSettingsNotifier, AppSettings>(
      () => AppSettingsNotifier(),
    );

// Convenience providers for individual settings
final showWebfInspectorProvider = Provider<bool>((ref) {
  return ref.watch(appSettingsProvider).value?.showWebfInspector ?? false;
});

final cacheControllersProvider = Provider<bool>((ref) {
  return ref.watch(appSettingsProvider).value?.cacheControllers ?? false;
});

final themeModeProvider = Provider<ThemeMode>((ref) {
  return ref.watch(appSettingsProvider).value?.themeMode ?? ThemeMode.system;
});

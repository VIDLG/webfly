import 'package:hooks_riverpod/hooks_riverpod.dart'
    show AsyncNotifier, AsyncNotifierProvider, AsyncValue;
import 'package:shared_preferences/shared_preferences.dart'
    show SharedPreferences;

class AppSettingsStorage {
  static const _showInspectorKey = 'show_webf_inspector';

  final SharedPreferences _prefs;

  AppSettingsStorage._(this._prefs);

  static Future<AppSettingsStorage> create() async {
    final prefs = await SharedPreferences.getInstance();
    return AppSettingsStorage._(prefs);
  }

  bool getShowWebfInspector() {
    return _prefs.getBool(_showInspectorKey) ?? false;
  }

  Future<void> setShowWebfInspector(bool value) async {
    await _prefs.setBool(_showInspectorKey, value);
  }
}

// Show WebF Inspector Provider
class ShowWebfInspectorNotifier extends AsyncNotifier<bool> {
  final Future<AppSettingsStorage> _storageFuture = AppSettingsStorage.create();
  AppSettingsStorage? _storage;

  @override
  Future<bool> build() async {
    final storage = await _ensureStorage();
    return storage.getShowWebfInspector();
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

  Future<void> setShowWebfInspector(bool value) async {
    final storage = await _ensureStorage();
    await storage.setShowWebfInspector(value);
    state = AsyncValue.data(value);
  }
}

final showWebfInspectorProvider =
    AsyncNotifierProvider<ShowWebfInspectorNotifier, bool>(
      () => ShowWebfInspectorNotifier(),
    );

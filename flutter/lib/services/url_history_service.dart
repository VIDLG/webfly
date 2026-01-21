import 'dart:convert' show jsonDecode, jsonEncode;
import 'package:hooks_riverpod/hooks_riverpod.dart'
    show AsyncNotifier, AsyncNotifierProvider, AsyncValue;
import 'package:shared_preferences/shared_preferences.dart'
    show SharedPreferences;

/// URL history storage
class UrlHistoryStorage {
  static const _historyKey = 'url_history';
  static const _maxHistorySize = 10;

  final SharedPreferences _prefs;

  UrlHistoryStorage._(this._prefs);

  static Future<UrlHistoryStorage> create() async {
    final prefs = await SharedPreferences.getInstance();
    return UrlHistoryStorage._(prefs);
  }

  List<String> getHistory() {
    final jsonString = _prefs.getString(_historyKey);
    if (jsonString == null) return [];

    try {
      final List<dynamic> decoded = jsonDecode(jsonString);
      return decoded.cast<String>();
    } catch (_) {
      return [];
    }
  }

  Future<void> addUrl(String url) async {
    final currentHistory = getHistory();
    final updatedHistory = _buildUpdatedHistory(currentHistory, url);
    await _saveHistory(updatedHistory);
  }

  Future<void> removeUrl(String url) async {
    final currentHistory = getHistory();
    final updatedHistory = currentHistory.where((item) => item != url).toList();
    await _saveHistory(updatedHistory);
  }

  Future<void> clearHistory() async {
    await _prefs.remove(_historyKey);
  }

  List<String> _buildUpdatedHistory(List<String> current, String newUrl) {
    final withoutDuplicates = current.where((url) => url != newUrl).toList();
    return [newUrl, ...withoutDuplicates].take(_maxHistorySize).toList();
  }

  Future<void> _saveHistory(List<String> history) async {
    await _prefs.setString(_historyKey, jsonEncode(history));
  }
}

/// Notifier that manages URL history state
class UrlHistoryNotifier extends AsyncNotifier<List<String>> {
  final Future<UrlHistoryStorage> _storageFuture = UrlHistoryStorage.create();
  UrlHistoryStorage? _storage;

  @override
  Future<List<String>> build() async {
    final storage = await _ensureStorage();
    return storage.getHistory();
  }

  Future<UrlHistoryStorage> _ensureStorage() async {
    final cached = _storage;
    if (cached != null) {
      return cached;
    }
    final storage = await _storageFuture;
    _storage = storage;
    return storage;
  }

  Future<void> addUrl(String url) async {
    final storage = await _ensureStorage();
    await storage.addUrl(url);
    state = AsyncValue.data(storage.getHistory());
  }

  Future<void> removeUrl(String url) async {
    final storage = await _ensureStorage();
    await storage.removeUrl(url);
    state = AsyncValue.data(storage.getHistory());
  }

  Future<void> clearHistory() async {
    final storage = await _ensureStorage();
    await storage.clearHistory();
    state = const AsyncValue.data([]);
  }

  void refresh() {
    final storage = _storage;
    if (storage == null) {
      return;
    }
    state = AsyncValue.data(storage.getHistory());
  }
}

/// Global provider for URL history
final urlHistoryProvider =
    AsyncNotifierProvider<UrlHistoryNotifier, List<String>>(
      () => UrlHistoryNotifier(),
    );

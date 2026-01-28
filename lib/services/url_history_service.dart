import 'dart:convert' show jsonDecode, jsonEncode;
import 'package:signals_flutter/signals_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart'
    show SharedPreferences;

/// URL history entry with URL and path
class UrlHistoryEntry {
  final String url;
  final String path;

  UrlHistoryEntry({required this.url, this.path = '/'});

  String get fullUrl => '$url${path == '/' ? '' : path}';

  factory UrlHistoryEntry.fromJson(Map<String, dynamic> json) {
    return UrlHistoryEntry(
      url: json['url'] as String,
      path: json['path'] as String? ?? '/',
    );
  }

  Map<String, dynamic> toJson() => {'url': url, 'path': path};

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is UrlHistoryEntry &&
          runtimeType == other.runtimeType &&
          url == other.url &&
          path == other.path;

  @override
  int get hashCode => url.hashCode ^ path.hashCode;
}

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

  List<UrlHistoryEntry> getHistory() {
    final jsonString = _prefs.getString(_historyKey);
    if (jsonString == null) return [];

    try {
      final List<dynamic> decoded = jsonDecode(jsonString);
      return decoded
          .map((item) {
            // Support old format (string) and new format (map)
            if (item is String) {
              return UrlHistoryEntry(url: item, path: '/');
            } else if (item is Map<String, dynamic>) {
              return UrlHistoryEntry.fromJson(item);
            }
            return UrlHistoryEntry(url: '', path: '/');
          })
          .where((entry) => entry.url.isNotEmpty)
          .toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> addEntry(String url, String path) async {
    final currentHistory = getHistory();
    final newEntry = UrlHistoryEntry(url: url, path: path);
    final updatedHistory = _buildUpdatedHistory(currentHistory, newEntry);
    await _saveHistory(updatedHistory);
  }

  Future<void> removeEntry(UrlHistoryEntry entry) async {
    final currentHistory = getHistory();
    final updatedHistory = currentHistory
        .where((item) => item != entry)
        .toList();
    await _saveHistory(updatedHistory);
  }

  Future<void> clearHistory() async {
    await _prefs.remove(_historyKey);
  }

  Future<void> reorderHistory(int oldIndex, int newIndex) async {
    final currentHistory = getHistory();
    if (oldIndex < 0 ||
        oldIndex >= currentHistory.length ||
        newIndex < 0 ||
        newIndex >= currentHistory.length) {
      return;
    }
    final items = List<UrlHistoryEntry>.from(currentHistory);
    final item = items.removeAt(oldIndex);
    items.insert(newIndex, item);
    await _saveHistory(items);
  }

  List<UrlHistoryEntry> _buildUpdatedHistory(
    List<UrlHistoryEntry> current,
    UrlHistoryEntry newEntry,
  ) {
    final withoutDuplicates = current
        .where((entry) => entry != newEntry)
        .toList();
    return [newEntry, ...withoutDuplicates].take(_maxHistorySize).toList();
  }

  Future<void> _saveHistory(List<UrlHistoryEntry> history) async {
    final jsonList = history.map((entry) => entry.toJson()).toList();
    await _prefs.setString(_historyKey, jsonEncode(jsonList));
  }
}

// URL history signal
final urlHistorySignal = signal<List<UrlHistoryEntry>>([]);

// Initialize URL history from storage
Future<void> initializeUrlHistory() async {
  final storage = await UrlHistoryStorage.create();
  urlHistorySignal.value = storage.getHistory();
}

// URL history operations
class UrlHistoryOperations {
  static Future<UrlHistoryStorage> _getStorage() async {
    return await UrlHistoryStorage.create();
  }

  static Future<void> addEntry(String url, String path) async {
    final storage = await _getStorage();
    await storage.addEntry(url, path);
    urlHistorySignal.value = storage.getHistory();
  }

  static Future<void> removeEntry(UrlHistoryEntry entry) async {
    final storage = await _getStorage();
    await storage.removeEntry(entry);
    urlHistorySignal.value = storage.getHistory();
  }

  static Future<void> clearHistory() async {
    final storage = await _getStorage();
    await storage.clearHistory();
    urlHistorySignal.value = [];
  }

  static Future<void> reorderEntries(int oldIndex, int newIndex) async {
    final storage = await _getStorage();
    await storage.reorderHistory(oldIndex, newIndex);
    urlHistorySignal.value = storage.getHistory();
  }

  static Future<void> refresh() async {
    final storage = await _getStorage();
    urlHistorySignal.value = storage.getHistory();
  }
}

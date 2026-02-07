import 'dart:convert' show jsonDecode, jsonEncode;
import 'package:shared_preferences/shared_preferences.dart'
    show SharedPreferences;
import 'package:signals_flutter/signals_flutter.dart';

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

/// URL history store: persistence (SharedPreferences) + reactive signal.
class UrlHistory {
  static const _historyKey = 'url_history';
  static const _maxHistorySize = 10;

  final SharedPreferences _prefs;

  final history = listSignal<UrlHistoryEntry>([]);

  UrlHistory._(this._prefs);

  static Future<UrlHistory> create() async {
    final prefs = await SharedPreferences.getInstance();
    final store = UrlHistory._(prefs);

    untracked(() {
      store.history.value = store._loadFromPrefs();
    });

    effect(() {
      final list = store.history.value;
      final jsonList = list.map((e) => e.toJson()).toList();
      store._prefs
          .setString(_historyKey, jsonEncode(jsonList))
          .catchError((_) => false);
    });

    return store;
  }

  List<UrlHistoryEntry> _loadFromPrefs() {
    final jsonString = _prefs.getString(_historyKey);
    if (jsonString == null) return [];

    try {
      final List<dynamic> decoded = jsonDecode(jsonString);
      return decoded
          .map((item) {
            if (item is String) {
              return UrlHistoryEntry(url: item, path: '/');
            }
            if (item is Map<String, dynamic>) {
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

  void addEntry(String url, String path) {
    final newEntry = UrlHistoryEntry(url: url, path: path);
    history.removeWhere((e) => e == newEntry);
    history.insert(0, newEntry);
    while (history.length > _maxHistorySize) {
      history.removeLast();
    }
  }

  void removeEntry(UrlHistoryEntry entry) {
    history.remove(entry);
  }

  void clearHistory() {
    history.clear();
  }

  void reorderEntries(int oldIndex, int newIndex) {
    if (oldIndex < 0 ||
        oldIndex >= history.length ||
        newIndex < 0 ||
        newIndex >= history.length) {
      return;
    }
    final item = history.removeAt(oldIndex);
    history.insert(newIndex, item);
  }

  void refresh() {
    history
      ..clear()
      ..addAll(_loadFromPrefs());
  }
}

// ---------------------------------------------------------------------------
// Singleton + public API
// ---------------------------------------------------------------------------

UrlHistory? _store;

ListSignal<UrlHistoryEntry> get urlHistorySignal => _store!.history;

Future<void> initializeUrlHistory() async {
  try {
    _store = await UrlHistory.create();
  } catch (_) {
    _store = null;
  }
}

void addUrlHistoryEntry(String url, String path) {
  _store?.addEntry(url, path);
}

void removeUrlHistoryEntry(UrlHistoryEntry entry) {
  _store?.removeEntry(entry);
}

void clearUrlHistory() {
  _store?.clearHistory();
}

void reorderUrlHistoryEntries(int oldIndex, int newIndex) {
  _store?.reorderEntries(oldIndex, newIndex);
}

void refreshUrlHistory() {
  _store?.refresh();
}

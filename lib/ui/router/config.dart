// Route path constants (exported for router configuration)
//
// Routing conventions:
// - `/webf` and `/app` are stable, public wrapper routes for WebF and MUST NOT change.
// - Flutter-native screens use a dedicated prefix to avoid clashing with WebF inner routes.
// NOTE: go_router forbids route paths ending with '/' except for the top '/' route.
// So the launcher cannot be '/_/' and must be '/_'.
const String kLauncherPath = '/_';
// Optional alias for deep-links/bookmarks; handled via GoRouter.redirect.
const String kLauncherAliasPath = '/_/';
const String kFlutterPrefix = '/_';
const String kScannerPath = '$kFlutterPrefix/scanner';
const String kNativeDiagnosticsPath = '$kFlutterPrefix/native-diagnostics';
const String kNativeDiagnosticsLogsPath = '$kNativeDiagnosticsPath/logs';
const String kBleDiagnosticsPath = '$kNativeDiagnosticsPath/ble';
const String kWebfRoutePath = '/webf';
const String kUseCasesPath = '$kFlutterPrefix/usecases'; // Dedicated wrapper route for use cases
const String kAppRoutePath =
  '/app'; // Hybrid routing uses query params instead of path params

// WebF inner router root path (used inside the `path` query param for hybrid routes).
const String kWebfInnerRootPath = '/';

// Asset HTTP Server configuration
const int kAssetHttpServerPort = 8765; // Fixed port for serving assets

// Query parameter keys (exported for router configuration)
const String kUrlParam = 'url';
const String kBaseParam = 'base';
const String kPathParam = 'path'; // WebF route path (in query param)
const String kTitleParam = 'title'; // Optional title for AppBar

/// Returns whether [path] is a Flutter wrapper route for WebF hybrid routing.
///
/// In hybrid routing, the actual WebF internal route lives in query param
/// [kPathParam], while the Flutter route stays on [kAppRoutePath] (and sometimes
/// [kUseCasesPath]).
bool isHybridWrapperRoutePath(String path) {
  return path == kAppRoutePath || path == kUseCasesPath;
}

/// Normalizes a WebF internal route *location*.
///
/// Accepts path-only (`/led`) and path+query/hash (`/led?css=0#top`).
///
/// In hybrid routing, the `path` query param is used as WebF's `initialRoute`/
/// router location, so allowing query/hash makes it possible to deep-link
/// precisely into a page.
String? normalizeWebfInnerPath(String? rawPath) {
  if (rawPath == null) return null;
  final trimmed = rawPath.trim();
  if (trimmed.isEmpty) return null;
  try {
    final uri = Uri.parse(trimmed.startsWith('/') ? trimmed : '/$trimmed');
    final path = uri.path.isEmpty ? '/' : uri.path;
    final query = uri.hasQuery ? '?${uri.query}' : '';
    final fragment = uri.hasFragment ? '#${uri.fragment}' : '';
    return '$path$query$fragment';
  } catch (_) {
    return trimmed.startsWith('/') ? trimmed : '/$trimmed';
  }
}

/// Extracts the WebF internal route from a hybrid wrapper URI.
///
/// Returns null when [kPathParam] is missing/empty.
String? extractHybridInnerPath(Uri uri) {
  return normalizeWebfInnerPath(uri.queryParameters[kPathParam]);
}

/// Generate default base/controller name from URL
String generateDefaultControllerName(String url) => 'webf-${url.hashCode}';

/// Build WebF Controller name from base and route
String buildWebfControllerName(String base, String routePath) {
  final sanitized = routePath.replaceAll('/', '_').replaceAll(':', '_');
  return '$base:$sanitized';
}

/// Build single WebF page URL
String buildWebFUrl(String url) {
  assert(url.isNotEmpty, 'url cannot be empty');
  final encodedUrl = Uri.encodeComponent(url);
  return '$kWebfRoutePath?$kUrlParam=$encodedUrl';
}

/// Build WebF Hybrid Routing URL
String buildWebFRouteUrl({
  required String url,
  required String route,
  required String path,
  String? base,
  String? title,
}) {
  assert(path.isNotEmpty, 'path cannot be empty');
  assert(url.isNotEmpty, 'url cannot be empty');
  final encodedUrl = Uri.encodeComponent(url);
  final encodedBase = Uri.encodeComponent(
    base ?? generateDefaultControllerName(url),
  );
  final encodedPath = Uri.encodeComponent(path);
  var result =
      '$route?$kUrlParam=$encodedUrl&$kBaseParam=$encodedBase&$kPathParam=$encodedPath';
  if (title != null) {
    final encodedTitle = Uri.encodeComponent(title);
    result += '&$kTitleParam=$encodedTitle';
  }
  return result;
}

/// Build WebF Hybrid Routing URL from current URI
String buildWebFRouteUrlFromUri({
  required Uri uri,
  required String route,
  required String path,
}) {
  assert(path.isNotEmpty, 'path cannot be empty');
  final url = uri.queryParameters[kUrlParam];
  assert(url != null && url.isNotEmpty, 'url parameter missing in URI');
  final base = uri.queryParameters[kBaseParam];
  return buildWebFRouteUrl(url: url!, route: route, path: path, base: base);
}

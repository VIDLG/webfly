// Route path constants (exported for router configuration)
const String kLauncherPath = '/';
const String kScannerPath = '/scanner';
const String kWebfRoutePath = '/webf';
const String kUseCasesPath = '/usecases'; // Dedicated route for use cases
const String kAppRoutePath =
    '/app'; // Hybrid routing uses query params instead of path params

// Asset HTTP Server configuration
const int kAssetHttpServerPort = 8765; // Fixed port for serving assets

// Query parameter keys (exported for router configuration)
const String kUrlParam = 'url';
const String kBaseParam = 'base';
const String kPathParam = 'path'; // WebF route path (in query param)
const String kTitleParam = 'title'; // Optional title for AppBar

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

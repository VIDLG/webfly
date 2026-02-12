import 'package:webfly_webf_view/webfly_webf_view.dart';

// Route path constants (exported for router configuration)
//
// Routing conventions:
// - All Flutter-managed routes live under `/_` (the Flutter prefix).
// - Flutter-native screens use sub-routes to avoid clashing with WebF inner routes.
// NOTE: go_router forbids route paths ending with '/' except for the top '/' route.
// So the launcher cannot be '/_/' and must be '/_'.
const String launcherPath = '/_';
// Optional alias for deep-links/bookmarks; handled via GoRouter.redirect.
const String launcherAliasPath = '/_/';
const String _prefix = WebfHybridConfig.defaultFlutterPrefix;
const String scannerPath = '$_prefix/scanner';
const String nativeDiagnosticsPath = '$_prefix/native-diagnostics';
const String nativeDiagnosticsLogsPath = '$nativeDiagnosticsPath/logs';
const String bleDiagnosticsPath = '$nativeDiagnosticsPath/ble';
const String useCasesMenuPath = '$_prefix/use_cases_menu';
const String useCasesPath =
    '$_prefix/usecases'; // Dedicated wrapper route for use cases
const String appRoutePath =
    '$_prefix/app'; // Hybrid routing uses query params instead of path params

// Asset HTTP Server configuration
const int assetHttpServerPort = 8765; // Fixed port for serving assets

// Query parameter keys — aligned with package defaults from WebfHybridConfig.
const String urlParam = WebfHybridConfig.defaultBundleUrlParam;
const String baseParam = WebfHybridConfig.defaultControllerParam;
const String locParam = WebfHybridConfig.defaultLocationParam;
const String titleParam = 'title'; // Optional title for AppBar (host-only)

/// Generate default base/controller name from URL
String generateDefaultControllerName(String url) => 'webf-${url.hashCode}';

/// Builds the full URL for a WebF hybrid route.
///
/// In hybrid routing, Flutter stays on a wrapper route ([route], e.g. [appRoutePath])
/// and the WebF app is loaded with [url]. The WebF inner route is passed via the
/// [locParam] query parameter ([path]). Optional [base] is used as the controller
/// name; if omitted, it is derived from [url]. Optional [title] is exposed as a
/// query param for the AppBar.
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
      '$route?$urlParam=$encodedUrl&$baseParam=$encodedBase&$locParam=$encodedPath';
  if (title != null) {
    final encodedTitle = Uri.encodeComponent(title);
    result += '&$titleParam=$encodedTitle';
  }
  return result;
}

/// Global go_router delegate instance used by WebFView.
final goRouterDelegate = defaultGoRouterDelegate;

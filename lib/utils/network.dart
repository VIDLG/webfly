/// Network and URL utility functions
library;

/// Validates if a string is a valid HTTP or HTTPS URL.
bool isValidHttpUrl(String input) {
  final uri = Uri.tryParse(input);
  return uri != null && (uri.scheme == 'http' || uri.scheme == 'https');
}

/// Extracts the path component from a route path, removing query string and fragment.
/// 
/// This is useful when working with WebF router, which only matches the path component,
/// not query string or fragment. Query string is available via window.location.search
/// in the frontend, so we only pass the path part here.
/// 
/// Examples:
/// - '/led?css=0' -> '/led'
/// - '/led#top' -> '/led'
/// - '/led?css=0#top' -> '/led'
/// - '/led' -> '/led'
/// - '' -> '/'
String extractPathOnly(String routePath) {
  try {
    final uri = Uri.parse(routePath);
    return uri.path.isEmpty ? '/' : uri.path;
  } catch (_) {
    // If parsing fails, try to extract path manually
    final queryIndex = routePath.indexOf('?');
    final hashIndex = routePath.indexOf('#');
    if (queryIndex < 0 && hashIndex < 0) return routePath;
    final endIndex = (queryIndex < 0 || hashIndex < 0)
        ? (queryIndex < 0 ? hashIndex : queryIndex)
        : (queryIndex < hashIndex ? queryIndex : hashIndex);
    final pathOnly = routePath.substring(0, endIndex);
    return pathOnly.isEmpty ? '/' : pathOnly;
  }
}

/// Normalizes a route path location.
/// 
/// Accepts path-only (`/led`) and path+query/hash (`/led?css=0#top`).
/// Ensures the path starts with '/' and preserves query string and fragment.
/// 
/// Examples:
/// - '/led' -> '/led'
/// - 'led' -> '/led'
/// - '/led?css=0#top' -> '/led?css=0#top'
/// - 'led?css=0' -> '/led?css=0'
/// - null -> null
/// - '' -> null
String? normalizeRoutePath(String? rawPath) {
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

/// Generates a default controller name from a URL.
/// 
/// Uses the URL's hash code to ensure consistent naming for the same URL.
/// 
/// Example:
/// - 'https://example.com/app.js' -> 'webf-1234567890'
String generateDefaultControllerName(String url) {
  return 'webf-${url.hashCode}';
}

/// Builds a WebF controller name from base and route path.
/// 
/// Sanitizes the route path by replacing '/' and ':' with '_' to create
/// a valid controller name identifier.
/// 
/// Examples:
/// - base: 'webf-123', routePath: '/led' -> 'webf-123:_led'
/// - base: 'webf-123', routePath: '/led/:id' -> 'webf-123:_led__id'
String buildWebfControllerName(String base, String routePath) {
  final sanitized = routePath.replaceAll('/', '_').replaceAll(':', '_');
  return '$base:$sanitized';
}

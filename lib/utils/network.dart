/// Network and URL utility functions
library;

import 'package:anyhow/anyhow.dart';

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
Result<String> extractPathOnly(String routePath) {
  try {
    final uri = Uri.parse(routePath);
    return Ok(uri.path.isEmpty ? '/' : uri.path);
  } catch (e, stackTrace) {
    return Err<String>(Error(e)).context('Invalid route path').context(
      <String, Object?>{
        'routePath': routePath,
        'stackTrace': stackTrace.toString(),
      },
    );
  }
}

/// Network and URL utility functions
library;

/// Validates if a string is a valid HTTP or HTTPS URL.
bool isValidHttpUrl(String input) {
  final uri = Uri.tryParse(input);
  return uri != null && (uri.scheme == 'http' || uri.scheme == 'https');
}

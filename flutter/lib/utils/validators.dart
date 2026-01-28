bool isValidHttpUrl(String input) {
  final uri = Uri.tryParse(input);
  return uri != null && (uri.scheme == 'http' || uri.scheme == 'https');
}

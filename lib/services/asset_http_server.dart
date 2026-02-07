import 'dart:io';
import 'package:flutter/services.dart' show rootBundle;
import 'package:shelf/shelf.dart' as shelf;
import 'package:shelf/shelf_io.dart' as shelf_io;
import 'package:logger/logger.dart';
import '../ui/router/config.dart' show kAssetHttpServerPort;

/// HTTP server that serves embedded assets
/// Allows WebF to load assets via http://localhost:port/
class AssetHttpServer {
  static final AssetHttpServer _instance = AssetHttpServer._internal();
  factory AssetHttpServer() => _instance;
  AssetHttpServer._internal();

  final _logger = Logger();
  HttpServer? _server;
  int? _port;

  /// Check if server is running
  bool get isRunning => _server != null;

  /// Get the server port (null if not running)
  int? get port => _port;

  /// Get the base URL for accessing assets
  String? get baseUrl => _port != null ? 'http://localhost:$_port' : null;

  /// Start the HTTP server
  Future<void> start({int port = kAssetHttpServerPort}) async {
    if (_server != null) {
      _logger.i('Asset HTTP server already running on port $_port');
      return;
    }

    try {
      final handler = shelf.Pipeline()
          .addMiddleware(shelf.logRequests())
          .addHandler(_handleRequest);

      _server = await shelf_io.serve(
        handler,
        InternetAddress.loopbackIPv4,
        port,
      );
      _port = _server!.port;

      _logger.i('Asset HTTP server started on http://localhost:$_port');
    } catch (e) {
      _logger.e('Failed to start asset HTTP server', error: e);
      rethrow;
    }
  }

  /// Stop the HTTP server
  Future<void> stop() async {
    if (_server != null) {
      await _server!.close(force: true);
      _logger.i('Asset HTTP server stopped');
      _server = null;
      _port = null;
    }
  }

  /// Handle HTTP requests by serving assets
  Future<shelf.Response> _handleRequest(shelf.Request request) async {
    final path = request.url.path;
    _logger.i('🌐 HTTP Request: ${request.method} /$path');

    // Handle root path with a helpful response
    if (path.isEmpty || path == '/') {
      return _handleRootRequest();
    }

    // Handle other paths
    final assetPath = _mapRequestPath(path);
    _logger.i('📂 Mapped /$path -> $assetPath');

    try {
      // Load asset from bundle
      final bytes = await rootBundle.load(assetPath);
      final data = bytes.buffer.asUint8List();

      // Determine content type
      final contentType = _getContentType(assetPath);

      _logger.i('✅ Serving $assetPath (${data.length} bytes) as $contentType');

      return shelf.Response.ok(
        data,
        headers: {
          'Content-Type': contentType,
          'Access-Control-Allow-Origin': '*',
          'Cache-Control': 'public, max-age=3600',
        },
      );
    } catch (e) {
      _logger.w('Asset not found: $assetPath', error: e);
      return shelf.Response.notFound('Asset not found: /$path');
    }
  }

  /// Handle root path request with available frameworks
  Future<shelf.Response> _handleRootRequest() async {
    try {
      // Load the root index.html from assets
      final bytes = await rootBundle.load('assets/gen/use_cases/index.html');
      final htmlContent = String.fromCharCodes(bytes.buffer.asUint8List());

      return shelf.Response.ok(
        htmlContent,
        headers: {
          'Content-Type': 'text/html; charset=utf-8',
          'Access-Control-Allow-Origin': '*',
        },
      );
    } catch (e) {
      _logger.w('Failed to load root index.html', error: e);

      // Fallback to a simple HTML response
      const fallbackContent = '''
<!DOCTYPE html>
<html>
<head>
    <title>WebF Use Cases</title>
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
</head>
<body>
    <h1>WebF Use Cases</h1>
    <p>Framework selector not available.</p>
    <p><a href="/react/">React Use Cases</a></p>
    <p><a href="/vue/">Vue Use Cases</a></p>
</body>
</html>
''';

      return shelf.Response.ok(
        fallbackContent,
        headers: {
          'Content-Type': 'text/html; charset=utf-8',
          'Access-Control-Allow-Origin': '*',
        },
      );
    }
  }

  /// Map request path to actual asset path
  String _mapRequestPath(String path) {
    // Handle framework directory access patterns:
    // /react -> assets/gen/use_cases/react/index.html
    // /react/ -> assets/gen/use_cases/react/index.html
    // /react -> assets/gen/use_cases/react/index.html

    // Strip trailing slash if present
    final cleanPath = path.endsWith('/')
        ? path.substring(0, path.length - 1)
        : path;

    // Check if this is a framework root access (e.g., /react, /vue)
    // If the path contains no internal slashes and doesn't have an extension,
    // assume it's a framework directory and redirect to index.html
    if (!cleanPath.contains('/') && !cleanPath.contains('.')) {
      return 'assets/gen/use_cases/$cleanPath/index.html';
    }

    // All other paths -> direct mapping to gen/use_cases
    return 'assets/gen/use_cases/$path';
  }

  /// Get MIME content type based on file extension
  String _getContentType(String path) {
    if (path.endsWith('.html')) return 'text/html; charset=utf-8';
    if (path.endsWith('.js')) return 'application/javascript; charset=utf-8';
    if (path.endsWith('.css')) return 'text/css; charset=utf-8';
    if (path.endsWith('.json')) return 'application/json; charset=utf-8';
    if (path.endsWith('.png')) return 'image/png';
    if (path.endsWith('.jpg') || path.endsWith('.jpeg')) return 'image/jpeg';
    if (path.endsWith('.gif')) return 'image/gif';
    if (path.endsWith('.webp')) return 'image/webp';
    if (path.endsWith('.svg')) return 'image/svg+xml';
    if (path.endsWith('.ico')) return 'image/x-icon';
    if (path.endsWith('.woff2')) return 'font/woff2';
    if (path.endsWith('.woff')) return 'font/woff';
    if (path.endsWith('.ttf')) return 'font/ttf';
    return 'application/octet-stream';
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:url_launcher/url_launcher.dart';

class WebViewScreen extends StatefulWidget {
  const WebViewScreen({super.key, required this.url, required this.title});

  final String url;
  final String title;

  @override
  State<WebViewScreen> createState() => _WebViewScreenState();
}

class _WebViewScreenState extends State<WebViewScreen> {
  InAppWebViewController? _controller;
  bool _isLoading = true;
  double _progress = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => _controller?.reload(),
          ),
        ],
        bottom: _isLoading
            ? PreferredSize(
                preferredSize: const Size.fromHeight(2),
                child: LinearProgressIndicator(value: _progress),
              )
            : null,
      ),
      body: InAppWebView(
        initialUrlRequest: URLRequest(url: WebUri(widget.url)),
        initialSettings: InAppWebViewSettings(
          javaScriptEnabled: true,
          useOnLoadResource: true,
          useShouldOverrideUrlLoading: true,
        ),
        onWebViewCreated: (controller) {
          _controller = controller;
        },
        onLoadStart: (controller, url) {
          setState(() {
            _isLoading = true;
          });
        },
        onLoadStop: (controller, url) {
          setState(() {
            _isLoading = false;
          });
        },
        onProgressChanged: (controller, progress) {
          setState(() {
            _progress = progress / 100;
            _isLoading = progress < 100;
          });
        },
        shouldOverrideUrlLoading: (controller, navigationAction) async {
          return NavigationActionPolicy.ALLOW;
        },
        onReceivedError: (controller, request, error) {
          debugPrint('WebView error: ${error.description}');
        },
        onDownloadStartRequest: (controller, request) async {
          final uri = Uri.parse(request.url.toString());
          if (await canLaunchUrl(uri)) {
            await launchUrl(uri, mode: LaunchMode.externalApplication);
          }
        },
      ),
    );
  }
}

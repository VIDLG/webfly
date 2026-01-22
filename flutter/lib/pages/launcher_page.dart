import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show SystemNavigator;
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../hooks/use_route_focus.dart';
import '../services/app_settings_service.dart';
import '../services/url_history_service.dart';
import '../services/asset_http_server.dart';
import '../services/hybrid_controller_manager.dart';
import '../utils/validators.dart';
import '../widgets/url_history_list.dart';
import '../widgets/webf_inspector_overlay.dart';
import '../router/config.dart'
    show kScannerPath, kUseCasesPath, kAppRoutePath, buildWebFRouteUrl;

class LauncherPage extends HookConsumerWidget {
  const LauncherPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final urlController = useTextEditingController();
    final errorMessage = useState<String?>(null);
    final showInspector = ref.watch(showWebfInspectorProvider).value ?? false;
    final urls = ref.watch(urlHistoryProvider).value;

    useEffect(() {
      if (urls == null || urls.isEmpty) return null;
      if (urlController.text.isEmpty) {
        urlController.text = urls.first;
      }
      return null;
    }, [urls, urlController]);

    // Monitor route focus and clean up controllers when returning to launcher
    final isRouteFocused = useRouteFocus();
    useEffect(() {
      if (isRouteFocused.value) {
        // Dispose all controllers when this page regains focus
        // This ensures clean state when returning from WebF pages
        HybridControllerManager.instance.disposeAll();
      }
      return null;
    }, [isRouteFocused.value]);

    void openWebF(String url) {
      ref.read(urlHistoryProvider.notifier).addUrl(url);
      errorMessage.value = null;

      // Always use hybrid routing mode (shared controller)
      final routeUrl = buildWebFRouteUrl(
        url: url,
        route: kAppRoutePath,
        path: '/',
      );
      print('[LauncherPage] Navigating to hybrid route: $routeUrl');
      context.push(routeUrl, extra: {'initial': true, 'url': url});
    }

    Future<void> openScanner() async {
      final result = await context.push<String>(kScannerPath);
      if (result != null) {
        openWebF(result);
      }
    }

    void applyManualUrl() {
      final input = urlController.text.trim();
      if (input.isEmpty) {
        errorMessage.value = 'Please enter a URL';
        return;
      }
      if (!isValidHttpUrl(input)) {
        errorMessage.value = 'Please enter a valid http/https URL';
        return;
      }
      openWebF(input);
    }

    final theme = Theme.of(context);

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;

        // Show confirmation dialog
        final shouldPop = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Exit App?'),
            content: const Text('Do you want to exit the application?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text('Exit'),
              ),
            ],
          ),
        );

        if (shouldPop == true && context.mounted) {
          SystemNavigator.pop(); // Exit the app
        }
      },
      child: Scaffold(
        appBar: AppBar(title: const Text('WebFly'), centerTitle: true),
        body: Stack(
          children: [
            SafeArea(
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                  child: Column(
                    children: [
                      const SizedBox(height: 8),
                      _HeaderSection(),
                      const SizedBox(height: 20),
                      _UrlInputField(
                        controller: urlController,
                        errorMessage: errorMessage.value,
                        onClear: () {
                          urlController.clear();
                          errorMessage.value = null;
                        },
                        onSubmitted: (_) => applyManualUrl(),
                      ),
                      const SizedBox(height: 12),
                      SwitchListTile(
                        value: showInspector,
                        onChanged: (value) {
                          ref
                              .read(showWebfInspectorProvider.notifier)
                              .setShowWebfInspector(value);
                        },
                        title: const Text('Show Inspector'),
                        subtitle: Text(
                          'Display WebF element inspector overlay',
                          style: theme.textTheme.bodySmall,
                        ),
                        contentPadding: EdgeInsets.zero,
                      ),
                      const SizedBox(height: 16),
                      _ActionButtons(
                        onLaunch: applyManualUrl,
                        onScan: openScanner,
                      ),
                      const SizedBox(height: 24),
                      const _UseCasesCard(),
                      const SizedBox(height: 24),
                      if (urls != null && urls.isNotEmpty)
                        UrlHistoryList(onUrlTap: openWebF),
                    ],
                  ),
                ),
              ),
            ),
            if (showInspector) const WebFInspectorOverlay(),
          ],
        ),
      ),
    );
  }
}

// Private widget: Header section with icon and description
class _HeaderSection extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      children: [
        Icon(Icons.qr_code_scanner, size: 64, color: theme.colorScheme.primary),
        const SizedBox(height: 12),
        Text(
          'Enter a URL or scan a QR code to launch',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}

// Private widget: URL input field
class _UrlInputField extends StatelessWidget {
  const _UrlInputField({
    required this.controller,
    required this.errorMessage,
    required this.onClear,
    required this.onSubmitted,
  });

  final TextEditingController controller;
  final String? errorMessage;
  final VoidCallback onClear;
  final ValueChanged<String> onSubmitted;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(
        labelText: 'WebF Bundle URL',
        hintText: 'https://example.com/bundle.js',
        border: const OutlineInputBorder(),
        prefixIcon: const Icon(Icons.link),
        errorText: errorMessage,
        suffixIcon: IconButton(
          icon: const Icon(Icons.clear),
          onPressed: onClear,
        ),
      ),
      keyboardType: TextInputType.url,
      textInputAction: TextInputAction.go,
      onSubmitted: onSubmitted,
    );
  }
}

// Private widget: Action buttons (Launch & Scan)
class _ActionButtons extends StatelessWidget {
  const _ActionButtons({required this.onLaunch, required this.onScan});

  final VoidCallback onLaunch;
  final VoidCallback onScan;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: FilledButton.icon(
            onPressed: onLaunch,
            icon: const Icon(Icons.rocket_launch),
            label: const Text('Launch'),
          ),
        ),
        const SizedBox(width: 12),
        FilledButton.tonalIcon(
          onPressed: onScan,
          icon: const Icon(Icons.qr_code_scanner),
          label: const Text('Scan'),
        ),
      ],
    );
  }
}

// Private widget: Use Cases card
class _UseCasesCard extends ConsumerWidget {
  const _UseCasesCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    void onTap() {
      // Open use cases from local HTTP server
      final server = AssetHttpServer();
      if (!server.isRunning) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Asset server not running')),
        );
        return;
      }

      final useCaseUrl = '${server.baseUrl}/';
      ref.read(urlHistoryProvider.notifier).addUrl(useCaseUrl);
      final routeUrl = buildWebFRouteUrl(
        url: useCaseUrl,
        route: kUseCasesPath,
        path: '/',
      );
      print('[LauncherPage] Opening use cases: $routeUrl');
      context.push(routeUrl, extra: {'initial': true, 'url': useCaseUrl});
    }

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.dashboard,
                  size: 32,
                  color: theme.colorScheme.onPrimaryContainer,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Use Cases',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'React examples powered by WebF',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios,
                size: 16,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

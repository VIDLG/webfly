import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../services/asset_http_server.dart';
import '../../../services/url_history_service.dart';
import '../../router/config.dart' show kUseCasesPath, buildWebFRouteUrl;
import '../../../utils/app_logger.dart';

/// Use Cases card
class LauncherUseCasesCard extends StatelessWidget {
  const LauncherUseCasesCard({super.key});

  @override
  Widget build(BuildContext context) {
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
      UrlHistoryOperations.addEntry(useCaseUrl, '/');
      final routeUrl = buildWebFRouteUrl(
        url: useCaseUrl,
        route: kUseCasesPath,
        path: '/',
      );
      appLogger.d('[LauncherScreen] Opening use cases: $routeUrl');
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

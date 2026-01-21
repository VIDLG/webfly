import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart'
    show HookConsumerWidget, WidgetRef;
import '../services/url_history_service.dart' show urlHistoryProvider;

class UrlHistoryList extends HookConsumerWidget {
  final void Function(String url) onUrlTap;

  const UrlHistoryList({super.key, required this.onUrlTap});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final urls = ref.watch(urlHistoryProvider).value;
    if (urls == null) {
      return const SizedBox.shrink();
    }
    if (urls.isEmpty) {
      return const SizedBox.shrink();
    }

    Future<void> handleClear() async {
      final confirmed = await _showClearHistoryDialog(context);

      if (confirmed == true) {
        await ref.read(urlHistoryProvider.notifier).clearHistory();
      }
    }

    void handleDelete(String url) {
      ref.read(urlHistoryProvider.notifier).removeUrl(url);
    }

    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 32),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Recent URLs',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            TextButton.icon(
              onPressed: handleClear,
              icon: const Icon(Icons.delete_outline, size: 18),
              label: const Text('Clear All'),
            ),
          ],
        ),
        const SizedBox(height: 12),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: urls.length,
          itemBuilder: (context, index) {
            final url = urls[index];
            final isLast = index == urls.length - 1;
            return Padding(
              padding: EdgeInsets.only(bottom: isLast ? 0 : 8),
              child: _HistoryCard(
                url: url,
                isLatest: index == 0,
                onTap: () => onUrlTap(url),
                onDelete: () => handleDelete(url),
              ),
            );
          },
        ),
      ],
    );
  }
}

class _HistoryCard extends StatelessWidget {
  final String url;
  final bool isLatest;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const _HistoryCard({
    required this.url,
    required this.isLatest,
    required this.onTap,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      margin: EdgeInsets.zero,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  isLatest ? Icons.history : Icons.link,
                  color: theme.colorScheme.primary,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (isLatest)
                      Text(
                        'Last visited',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    Text(
                      url,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: theme.colorScheme.primary,
                        fontWeight: isLatest
                            ? FontWeight.w500
                            : FontWeight.normal,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close, size: 18),
                onPressed: onDelete,
                color: theme.colorScheme.onSurfaceVariant,
                tooltip: 'Remove',
              ),
            ],
          ),
        ),
      ),
    );
  }
}

Future<bool?> _showClearHistoryDialog(BuildContext context) {
  return showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Clear History'),
      content: const Text('Are you sure you want to clear all history?'),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, true),
          child: const Text('Clear'),
        ),
      ],
    ),
  );
}

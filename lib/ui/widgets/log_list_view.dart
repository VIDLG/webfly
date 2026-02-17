import 'package:flutter/material.dart';
import 'package:signals_flutter/signals_flutter.dart';

import '../native_diagnostics/core.dart';

class LogListView extends StatelessWidget {
  final TestLogBuffer buffer;
  final String emptyMessage;
  final bool showTimestamp;
  final bool showLevel;

  const LogListView({
    super.key,
    required this.buffer,
    this.emptyMessage = 'No logs yet.',
    this.showTimestamp = true,
    this.showLevel = true,
  });

  @override
  Widget build(BuildContext context) {
    return Watch((context) {
      final entries = buffer.entries.value;
      if (entries.isEmpty) {
        return Center(child: Text(emptyMessage));
      }

      return ListView.builder(
        padding: const EdgeInsets.all(12),
        itemCount: entries.length,
        itemBuilder: (context, index) {
          final e = entries[index];
          final time =
              '${e.timestamp.hour.toString().padLeft(2, '0')}:${e.timestamp.minute.toString().padLeft(2, '0')}:${e.timestamp.second.toString().padLeft(2, '0')}';

          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (showTimestamp) ...[
                  Text(
                    time,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(width: 10),
                ],
                if (showLevel) ...[
                  Text(
                    e.level.name.toUpperCase(),
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: e.level.color(context),
                    ),
                  ),
                  const SizedBox(width: 10),
                ],
                Expanded(
                  child: SelectableText(
                    '[${e.tag}] ${e.message}',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ),
              ],
            ),
          );
        },
      );
    });
  }
}

class LogViewerDialog extends StatelessWidget {
  final TestLogBuffer buffer;
  final String title;

  const LogViewerDialog({super.key, required this.buffer, this.title = 'Logs'});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: SizedBox(
        width: double.maxFinite,
        height: 500,
        child: Column(
          children: [
            AppBar(
              title: Text(title),
              automaticallyImplyLeading: false,
              actions: [
                IconButton(
                  tooltip: 'Clear',
                  onPressed: buffer.clear,
                  icon: const Icon(Icons.delete_outline),
                ),
                IconButton(
                  tooltip: 'Close',
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
            Expanded(
              child: LogListView(buffer: buffer, emptyMessage: 'No logs yet.'),
            ),
          ],
        ),
      ),
    );
  }
}

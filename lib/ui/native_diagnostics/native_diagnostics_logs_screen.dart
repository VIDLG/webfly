import 'package:flutter/material.dart';
import 'package:signals_flutter/signals_flutter.dart';

import 'core.dart';

class NativeDiagnosticsLogsScreen extends StatelessWidget {
  const NativeDiagnosticsLogsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final buffer = TestLogBuffer.instance;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Native Diagnostics Logs'),
        actions: [
          IconButton(
            tooltip: 'Clear',
            onPressed: buffer.clear,
            icon: const Icon(Icons.delete_outline),
          ),
        ],
      ),
      body: Watch((context) {
        final entries = buffer.entries.value;
        if (entries.isEmpty) {
          return const Center(
            child: Text('No logs yet. Run a test to see logs.'),
          );
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
                  Text(
                    time,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    e.level.name.toUpperCase(),
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: e.level.color(context),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      '[${e.tag}] ${e.message}',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ),
                ],
              ),
            );
          },
        );
      }),
    );
  }
}

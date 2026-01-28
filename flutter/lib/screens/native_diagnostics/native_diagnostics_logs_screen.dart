import 'package:flutter/material.dart';

import 'core.dart';

class NativeDiagnosticsLogsScreen extends StatelessWidget {
  const NativeDiagnosticsLogsScreen({super.key});

  String _levelLabel(TestLogLevel level) {
    return switch (level) {
      TestLogLevel.trace => 'TRACE',
      TestLogLevel.debug => 'DEBUG',
      TestLogLevel.info => 'INFO',
      TestLogLevel.warning => 'WARN',
      TestLogLevel.error => 'ERROR',
    };
  }

  Color? _levelColor(BuildContext context, TestLogLevel level) {
    final colors = Theme.of(context).colorScheme;
    return switch (level) {
      TestLogLevel.trace => colors.onSurfaceVariant,
      TestLogLevel.debug => colors.primary,
      TestLogLevel.info => colors.secondary,
      TestLogLevel.warning => colors.tertiary,
      TestLogLevel.error => colors.error,
    };
  }

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
      body: AnimatedBuilder(
        animation: buffer,
        builder: (context, _) {
          final entries = buffer.entries;
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
                      _levelLabel(e.level),
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: _levelColor(context, e.level),
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
        },
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../router/config.dart';
import 'core.dart';

class NativeDiagnosticsScreen extends StatelessWidget {
  const NativeDiagnosticsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Native Diagnostics'),
        actions: [
          IconButton(
            tooltip: 'Logs',
            onPressed: () => context.push(kNativeDiagnosticsLogsPath),
            icon: const Icon(Icons.article_outlined),
          ),
        ],
      ),
      body: ListView(
        children: [
          ...NativeTestRegistry.tests.expand((t) sync* {
            yield ListTile(
              leading: Icon(t.icon),
              title: Text(t.title),
              subtitle: Text(t.subtitle),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => context.push(t.routePath),
            );
            yield const Divider(height: 1);
          }),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Text(
              'Add more tests by registering entries in NativeTestRegistry.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

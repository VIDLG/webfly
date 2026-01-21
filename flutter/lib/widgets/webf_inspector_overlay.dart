import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart' show useMemoized;
import 'package:hooks_riverpod/hooks_riverpod.dart'
    show HookConsumerWidget, WidgetRef;
import 'package:webf/devtools.dart' show WebFInspectorFloatingPanel;
import '../services/app_settings_service.dart' show showWebfInspectorProvider;

class WebFInspectorOverlay extends HookConsumerWidget {
  const WebFInspectorOverlay({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final showInspector = ref.watch(showWebfInspectorProvider).value ?? false;
    if (!showInspector) {
      return const SizedBox.shrink();
    }
    final size = useMemoized(() => MediaQuery.sizeOf(context));
    if (size.width <= 0 || size.height <= 0) {
      return const SizedBox.shrink();
    }
    return const WebFInspectorFloatingPanel();
  }
}

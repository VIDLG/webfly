import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:signals_flutter/signals_flutter.dart';
import 'package:webf/devtools.dart' show WebFInspectorFloatingPanel;
import '../services/app_settings_service.dart' show showWebfInspectorSignal;

class WebFInspectorOverlay extends HookWidget {
  const WebFInspectorOverlay({super.key});

  @override
  Widget build(BuildContext context) {
    final showInspector = showWebfInspectorSignal.watch(context);
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

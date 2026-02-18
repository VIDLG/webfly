import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:signals_flutter/signals_flutter.dart';

import '../../store/app_settings.dart';
import '../router/app_router.dart';
import '../router/config.dart';

// Global so position persists across page switches.
final _fabOffset = signal<Offset?>(null);

class LogsFab extends HookWidget {
  const LogsFab({super.key});

  static const _size = 40.0;
  static const _margin = 12.0;

  @override
  Widget build(BuildContext context) {
    final show = showLogsFabSignal.watch(context);
    if (!show) return const SizedBox.shrink();

    final offset = _fabOffset.watch(context);
    final fabKey = useMemoized(() => GlobalKey());
    final screen = MediaQuery.sizeOf(context);

    Widget fab() => Opacity(
      opacity: 0.6,
      child: SizedBox(
        key: fabKey,
        width: _size,
        height: _size,
        child: FloatingActionButton.small(
          heroTag: 'logs_fab',
          onPressed: () => goRouter.push(logsPath),
          child: const Icon(Icons.article_outlined, size: 20),
        ),
      ),
    );

    void onPanStart(DragStartDetails _) {
      if (_fabOffset.value != null) return;
      final box = fabKey.currentContext?.findRenderObject() as RenderBox?;
      if (box != null) {
        _fabOffset.value = box.localToGlobal(Offset.zero);
      }
    }

    void onPanUpdate(DragUpdateDetails details) {
      final cur = _fabOffset.value;
      if (cur == null) return;
      _fabOffset.value = Offset(
        (cur.dx + details.delta.dx).clamp(0.0, screen.width - _size),
        (cur.dy + details.delta.dy).clamp(0.0, screen.height - _size),
      );
    }

    // Before first drag: anchor to bottom-right via right/bottom.
    // After drag: switch to absolute left/top positioning.
    if (offset == null) {
      return Positioned(
        right: _margin,
        bottom: _margin,
        child: GestureDetector(
          onPanStart: onPanStart,
          onPanUpdate: onPanUpdate,
          child: fab(),
        ),
      );
    }

    return Positioned(
      left: offset.dx,
      top: offset.dy,
      child: GestureDetector(onPanUpdate: onPanUpdate, child: fab()),
    );
  }
}

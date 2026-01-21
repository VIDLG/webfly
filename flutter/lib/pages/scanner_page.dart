import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart' show useEffect, useMemoized;
import 'package:hooks_riverpod/hooks_riverpod.dart'
    show HookConsumerWidget, WidgetRef;
import 'package:mobile_scanner/mobile_scanner.dart'
    show BarcodeCapture, MobileScanner, MobileScannerController;
import '../services/url_history_service.dart' show urlHistoryProvider;
import '../utils/validators.dart' show isValidHttpUrl;

class ScannerPage extends HookConsumerWidget {
  const ScannerPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controller = useMemoized(() => MobileScannerController());
    useEffect(() {
      return controller.dispose;
    }, [controller]);

    void handleBarcode(BarcodeCapture capture) {
      final rawValue = capture.barcodes.isNotEmpty
          ? capture.barcodes.first.rawValue
          : null;
      if (rawValue == null || rawValue.isEmpty) return;

      if (isValidHttpUrl(rawValue)) {
        controller.stop();
        ref.read(urlHistoryProvider.notifier).addUrl(rawValue);
        Navigator.of(context).pop(rawValue);
      }
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Scan QR Code'), centerTitle: true),
      body: Stack(
        children: [
          MobileScanner(controller: controller, onDetect: handleBarcode),
          Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              margin: const EdgeInsets.all(24),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              decoration: BoxDecoration(
                color: const Color.fromRGBO(0, 0, 0, 0.7),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Text(
                'Scan QR code to open WebF page',
                style: TextStyle(color: Colors.white, fontSize: 16),
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

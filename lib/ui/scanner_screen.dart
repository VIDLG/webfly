import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_use/flutter_use.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile_scanner/mobile_scanner.dart'
    show BarcodeCapture, MobileScanner, MobileScannerController;
import '../utils/network.dart' show isValidHttpUrl;

class ScannerScreen extends HookWidget {
  const ScannerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = useMemoized(() => MobileScannerController());
    useUnmount(controller.dispose);

    void handleBarcode(BarcodeCapture capture) {
      final rawValue = capture.barcodes.isNotEmpty
          ? capture.barcodes.first.rawValue
          : null;
      if (rawValue == null || rawValue.isEmpty) return;

      if (isValidHttpUrl(rawValue)) {
        controller.stop();

        // Use the full URL as baseUrl, and default path to '/'
        // We do *not* split the path from the URL automatically, because usually
        // the scanned URL is the bundle URL itself (which may contain a path).
        final baseUrl = rawValue;
        const path = '/';

        context.pop({'url': baseUrl, 'path': path});
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

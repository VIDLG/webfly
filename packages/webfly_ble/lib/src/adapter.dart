import 'package:anyhow/anyhow.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart' as fbp;

import 'options.dart';

/// Turn on Bluetooth adapter (Android only). Returns [Result].
Future<Result<void>> bleTurnOn() async {
  return guardAsync(
    () => fbp.FlutterBluePlus.turnOn(),
  ).context('Failed to turn on Bluetooth');
}

/// Start scanning for BLE devices. Returns [Result].
Future<Result<void>> bleStartScan(ScanOptions? options) async {
  final opts = options ?? const ScanOptions();
  return guardAsync(() async {
    await fbp.FlutterBluePlus.startScan(
      withServices: opts.withServices,
      withRemoteIds: opts.withRemoteIds,
      withNames: opts.withNames,
      withKeywords: opts.withKeywords,
      withMsd: opts.fbpWithMsd,
      withServiceData: opts.fbpWithServiceData,
      timeout: opts.timeout,
      removeIfGone: opts.removeIfGone,
      continuousUpdates: opts.continuousUpdates,
      continuousDivisor: opts.continuousDivisor,
      oneByOne: opts.oneByOne,
      androidLegacy: opts.androidLegacy,
      androidScanMode: opts.androidScanMode,
      androidUsesFineLocation: opts.androidUsesFineLocation,
      androidCheckLocationServices: opts.androidCheckLocationServices,
      webOptionalServices: opts.webOptionalServices,
    );
  }).context('Failed to start scan');
}

/// Stop scanning. Returns [Result].
Future<Result<void>> bleStopScan() async {
  return guardAsync(
    () => fbp.FlutterBluePlus.stopScan(),
  ).context('Failed to stop scan');
}

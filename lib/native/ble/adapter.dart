import 'dart:async';

import 'package:anyhow/anyhow.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart' as fbp;
import 'serialization.dart';
import 'options.dart';
import 'webf.dart';

import '../../utils/stream_signal_context.dart';

/// Check if Bluetooth is supported on this device
Future<Result<bool>> bleIsSupported() async {
  return guardAsync(() => fbp.FlutterBluePlus.isSupported);
}

/// Current adapter state.
fbp.BluetoothAdapterState get bleAdapterStateNow => fbp.FlutterBluePlus.adapterStateNow;

/// Listen to adapter state changes
Stream<fbp.BluetoothAdapterState> get bleAdapterState => fbp.FlutterBluePlus.adapterState;

/// Reactive adapter state context.
///
/// Holds a live [Signal] with the current adapter state, and maintains a
/// single underlying stream subscription.
///
/// This is useful when multiple places need to react to adapter state changes
/// without each wiring their own listener.
class BleAdapterStateContext extends StreamSignalContext<fbp.BluetoothAdapterState> {
  BleAdapterStateContext._() 
    : super(bleAdapterState, bleAdapterStateNow) {
    start();
  }

  static final BleAdapterStateContext instance = BleAdapterStateContext._();
}

/// Global adapter state context.
///
/// Lazily creates the singleton when first accessed.
BleAdapterStateContext get bleAdapterStateContext => BleAdapterStateContext.instance;

/// Get adapter name
Future<String> get bleAdapterName async {
  return await fbp.FlutterBluePlus.adapterName;
}

/// Turn on Bluetooth adapter (Android only)
Future<Result<void>> bleTurnOn() async {
  return guardAsync(() => fbp.FlutterBluePlus.turnOn())
      .context('Failed to turn on Bluetooth');
}

/// Start scanning for BLE devices
/// 
/// Takes ScanOptions and passes them to FlutterBluePlus.startScan
Future<Result<void>> bleStartScan(ScanOptions? options) async {
  final opts = options ?? const ScanOptions();
  return guardAsync(() async {
    await fbp.FlutterBluePlus.startScan(
      withServices: opts.withServices,
      withRemoteIds: opts.withRemoteIds,
      withNames: opts.withNames,
      withKeywords: opts.withKeywords,
      withMsd: opts.withMsd,
      withServiceData: opts.withServiceData,
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

/// Stop scanning
Future<Result<void>> bleStopScan() async {
  return guardAsync(() => fbp.FlutterBluePlus.stopScan())
      .context('Failed to stop scan');
}

/// Get current scan results
List<fbp.ScanResult> get bleLastScanResults => fbp.FlutterBluePlus.lastScanResults;

/// Stream of scan results (includes previous results)
Stream<List<fbp.ScanResult>> get bleScanResults => fbp.FlutterBluePlus.scanResults;

/// Reactive scan results context.
class BleScanResultsContext extends StreamSignalContext<List<fbp.ScanResult>> {
  BleScanResultsContext._() 
    : super(bleScanResults, bleLastScanResults) {
    start();
  }

  static final BleScanResultsContext instance = BleScanResultsContext._();
}

/// Global scan results context.
BleScanResultsContext get bleScanResultsContext => BleScanResultsContext.instance;

/// Stream of new scan results only (cleared between scans)
Stream<List<fbp.ScanResult>> get bleOnScanResults => fbp.FlutterBluePlus.onScanResults;

/// Register a subscription to be canceled when scanning is complete
void bleCancelWhenScanComplete(StreamSubscription subscription) {
  fbp.FlutterBluePlus.cancelWhenScanComplete(subscription);
}

/// Check if currently scanning
bool get bleIsScanningNow => fbp.FlutterBluePlus.isScanningNow;

/// Stream of scanning state
Stream<bool> get bleIsScanning => fbp.FlutterBluePlus.isScanning;

/// Reactive scanning state context.
class BleIsScanningContext extends StreamSignalContext<bool> {
  BleIsScanningContext._() 
    : super(bleIsScanning, bleIsScanningNow) {
    start();
  }

  static final BleIsScanningContext instance = BleIsScanningContext._();
}

/// Global scanning state context.
BleIsScanningContext get bleIsScanningContext => BleIsScanningContext.instance;

/// Set log level
Future<void> bleSetLogLevel(fbp.LogLevel level, {bool color = true}) async {
  await fbp.FlutterBluePlus.setLogLevel(level, color: color);
}

/// Get FBP logs
Stream<String> get bleLogs => fbp.FlutterBluePlus.logs;

/// Set configurable options (iOS/MacOS only)
Future<void> bleSetOptions(SetOptions? options) async {
  final opts = options ?? const SetOptions();
  await fbp.FlutterBluePlus.setOptions(
    showPowerAlert: opts.showPowerAlert,
    restoreState: opts.restoreState,
  );
}

/// Request Bluetooth PHY support (Android only)
Future<fbp.PhySupport> bleGetPhySupport() async {
  return fbp.FlutterBluePlus.getPhySupport();
}

/// Get list of connected devices
List<fbp.BluetoothDevice> get bleConnectedDevices => fbp.FlutterBluePlus.connectedDevices;

/// Get system devices (connected to system but not app)
Future<List<fbp.BluetoothDevice>> bleSystemDevices(List<fbp.Guid> withServices) async {
  return fbp.FlutterBluePlus.systemDevices(withServices);
}

/// Get bonded devices (Android only)
Future<List<fbp.BluetoothDevice>> bleBondedDevices() async {
  return fbp.FlutterBluePlus.bondedDevices;
}



// ----------------------------------------------------------------------------
// Module Logic
// ----------------------------------------------------------------------------

extension BleAdapterModule on BleWebfModule {
  /// Check if BLE is supported on this device
  Future<Map<String, dynamic>> isSupported() async {
    final result = await bleIsSupported;
    return returnOk(result);
  }

  /// Get current adapter state
  Future<Map<String, dynamic>> getAdapterState() async {
    return returnOk(bleAdapterStateNow.toMap());
  }

  /// Turn on BLE adapter (Android only)
  Future<Map<String, dynamic>> turnOn() async {
    final result = await bleTurnOn();
    return result.toMap();
  }

  /// Start scanning for BLE devices
  /// Arguments: [{ timeout?: number, ... }]
  Future<Map<String, dynamic>> startScan(List<dynamic> arguments) async {
    final map = arguments.isNotEmpty ? arguments[0] as Map<String, dynamic>? : null;
    final options = ScanOptions.fromMap(map);
    
    final result = await bleStartScan(options);

    return result.toMap();
  }

  /// Stop scanning
  Future<Map<String, dynamic>> stopScan() async {
    final result = await bleStopScan();
    return result.toMap();
  }

  /// Get current scan results
  /// Returns: Array of scan result objects
  Future<Map<String, dynamic>> getScanResults() async {
    return returnOk(bleLastScanResults.toMap());
  }

  /// Check if currently scanning
  Future<Map<String, dynamic>> isScanning() async {
    return returnOk(bleIsScanningNow);
  }

  /// Get list of connected devices
  /// Returns: Array of device objects
  Future<Map<String, dynamic>> getConnectedDevices() async {
    return returnOk(bleConnectedDevices.toMap());
  }
}

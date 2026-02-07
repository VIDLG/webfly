import 'dart:async';

import 'package:anyhow/anyhow.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart' as fbp;

import '../../utils/stream_signal_context.dart';
import 'options.dart';

/// Reactive context for characteristic last value
class BleLastValueContext extends StreamSignalContext<List<int>> {
  BleLastValueContext(fbp.BluetoothCharacteristic characteristic)
    : super(characteristic.lastValueStream, characteristic.lastValue) {
    start();
  }
}

/// Reactive context for characteristic value received
class BleOnValueReceivedContext extends StreamSignalContext<List<int>> {
  BleOnValueReceivedContext(fbp.BluetoothCharacteristic characteristic)
    : super(characteristic.onValueReceived, []) {
    start();
  }
}

final _bleLastValueContexts = Expando<BleLastValueContext>();
final _bleOnValueReceivedContexts = Expando<BleOnValueReceivedContext>();

/// Release all characteristic contexts for a device (e.g. when disconnected).
void releaseBleCharacteristicContextsForDevice(fbp.BluetoothDevice device) {
  for (final service in device.servicesList) {
    for (final c in service.characteristics) {
      _bleLastValueContexts[c]?.dispose();
      _bleOnValueReceivedContexts[c]?.dispose();
    }
  }
}

extension BleCharacteristicExtensions on fbp.BluetoothCharacteristic {
  /// Stream of characteristic values (updated on read, write, notify)
  Stream<List<int>> get bleLastValueStream => lastValueStream;

  /// Reactive last value context (cached per characteristic).
  BleLastValueContext bleLastValueContext() {
    final ctx = _bleLastValueContexts[this];
    if (ctx != null && !ctx.isDisposed) return ctx;
    final n = BleLastValueContext(this);
    _bleLastValueContexts[this] = n;
    return n;
  }

  /// Stream of incoming values (Read response or Notification)
  /// Does NOT include local writes or initial value.
  Stream<List<int>> get bleOnValueReceived => onValueReceived;

  /// Reactive on value received context (cached per characteristic).
  BleOnValueReceivedContext bleOnValueReceivedContext() {
    final ctx = _bleOnValueReceivedContexts[this];
    if (ctx != null && !ctx.isDisposed) return ctx;
    final n = BleOnValueReceivedContext(this);
    _bleOnValueReceivedContexts[this] = n;
    return n;
  }

  /// Read a characteristic value
  Future<Result<List<int>>> bleRead(ReadCharacteristicOptions? options) async {
    final opts = options ?? const ReadCharacteristicOptions();
    return guardAsync(
      () => read(timeout: opts.timeout),
    ).context('Failed to read characteristic $uuid (Device: ${remoteId.str})');
  }

  /// Write to a characteristic
  Future<Result<void>> bleWrite(
    List<int> data,
    WriteCharacteristicOptions? options,
  ) async {
    final opts = options ?? const WriteCharacteristicOptions();
    return guardAsync(
      () => write(
        data,
        withoutResponse: opts.withoutResponse,
        allowLongWrite: opts.allowLongWrite,
        timeout: opts.timeout,
      ),
    ).context('Failed to write characteristic $uuid (Device: ${remoteId.str})');
  }

  /// Enable/disable notifications for a characteristic
  Future<Result<void>> bleSetNotifyValue(
    bool enable,
    NotifyCharacteristicOptions? options,
  ) async {
    final opts = options ?? const NotifyCharacteristicOptions();
    return guardAsync(
      () => setNotifyValue(
        enable,
        timeout: opts.timeout,
        forceIndications: opts.forceIndications,
      ),
    ).context(
      'Failed to set notify value for characteristic $uuid (Device: ${remoteId.str})',
    );
  }
}

// ----------------------------------------------------------------------------
// Module Logic
// ----------------------------------------------------------------------------

/// Find a characteristic by device/service/characteristic UUIDs.
/// Used by webf module; assumes device has been connected and services discovered.
Result<fbp.BluetoothCharacteristic> bleFindCharacteristic(
  String deviceId,
  String serviceUuid,
  String characteristicUuid,
) {
  final device = fbp.BluetoothDevice.fromId(deviceId);

  fbp.BluetoothService? service;
  for (final s in device.servicesList) {
    if (s.uuid.toString() == serviceUuid) {
      service = s;
      break;
    }
  }

  if (service == null) {
    return Err(Error('Service not found'));
  }

  for (final c in service.characteristics) {
    if (c.uuid.toString() == characteristicUuid) {
      return Ok(c);
    }
  }

  return Err(Error('Characteristic not found'));
}

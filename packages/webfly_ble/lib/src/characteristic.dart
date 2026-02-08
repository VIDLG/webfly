import 'package:anyhow/anyhow.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart' as fbp;

import 'options.dart';

extension BleCharacteristicExtensions on fbp.BluetoothCharacteristic {
  /// Read a characteristic value. Returns [Result].
  Future<Result<List<int>>> bleRead(ReadCharacteristicOptions? options) async {
    final opts = options ?? const ReadCharacteristicOptions();
    return guardAsync(
      () => read(timeout: opts.timeout),
    ).context('Failed to read characteristic $uuid (Device: ${remoteId.str})');
  }

  /// Write to a characteristic. Returns [Result].
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

  /// Enable/disable notifications for a characteristic. Returns [Result].
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

/// Find a characteristic by device/service/characteristic UUIDs.
/// Assumes device has been connected and services discovered. Returns [Result].
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

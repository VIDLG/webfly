import 'package:anyhow/anyhow.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart' as fbp;

import 'options.dart';

extension BleDeviceExtensions on fbp.BluetoothDevice {
  /// Connect to a BLE device. Returns [Result].
  Future<Result<void>> bleConnect(ConnectOptions? options) async {
    final opts = options ?? const ConnectOptions();
    return guardAsync(
      () => connect(
        license: opts.license,
        timeout: opts.timeout,
        mtu: opts.mtu,
        autoConnect: opts.autoConnect,
      ),
    ).context('Failed to connect to device: ${remoteId.str}');
  }

  /// Disconnect from a BLE device. Returns [Result].
  Future<Result<void>> bleDisconnect(DisconnectOptions? options) async {
    final opts = options ?? const DisconnectOptions();
    return guardAsync(
      () => disconnect(
        timeout: opts.timeout,
        queue: opts.queue,
        androidDelay: opts.androidDelay,
      ),
    ).context('Failed to disconnect from device: ${remoteId.str}');
  }

  /// Discover services for a connected device. Returns [Result].
  Future<Result<List<fbp.BluetoothService>>> bleDiscoverServices(
    DiscoverServicesOptions? options,
  ) async {
    final opts = options ?? const DiscoverServicesOptions();
    return guardAsync(
      () => discoverServices(
        subscribeToServicesChanged: opts.subscribeToServicesChanged,
        timeout: opts.timeout,
      ),
    ).context('Failed to discover services for device ${remoteId.str}');
  }
}

import 'dart:async';

import 'package:anyhow/anyhow.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart' as fbp;

import 'characteristic.dart';
import '../../utils/stream_signal_context.dart';
import 'options.dart';

/// Reactive context for device connection state (cached per device).
class BleConnectionStateContext
    extends StreamSignalContext<fbp.BluetoothConnectionState> {
  BleConnectionStateContext(this._device)
    : super(
        _device.connectionState,
        _device.isConnected
            ? fbp.BluetoothConnectionState.connected
            : fbp.BluetoothConnectionState.disconnected,
      ) {
    start();
  }

  final fbp.BluetoothDevice _device;

  @override
  void onValue(fbp.BluetoothConnectionState value) {
    if (value == fbp.BluetoothConnectionState.disconnected) {
      Future.microtask(() => releaseBleDeviceContexts(_device));
    }
  }
}

/// Reactive context for device MTU (cached per device).
class BleMtuContext extends StreamSignalContext<int> {
  BleMtuContext(fbp.BluetoothDevice device) : super(device.mtu, device.mtuNow) {
    start();
  }
}

final _bleConnectionStateContexts = Expando<BleConnectionStateContext>();
final _bleMtuContexts = Expando<BleMtuContext>();

/// Release device and its characteristic contexts (cancel subscriptions).
/// Called when connection state becomes disconnected.
void releaseBleDeviceContexts(fbp.BluetoothDevice device) {
  final conn = _bleConnectionStateContexts[device];
  if (conn != null && !conn.isDisposed) conn.dispose();
  final mtu = _bleMtuContexts[device];
  if (mtu != null && !mtu.isDisposed) mtu.dispose();
  releaseBleCharacteristicContextsForDevice(device);
}

extension BleDeviceExtensions on fbp.BluetoothDevice {
  /// Stream of connection state changes (our app ↔ device).
  Stream<fbp.BluetoothConnectionState> get bleConnectionState =>
      connectionState;

  /// Reactive connection state context (cached per device).
  BleConnectionStateContext bleConnectionStateContext() {
    final ctx = _bleConnectionStateContexts[this];
    if (ctx != null && !ctx.isDisposed) return ctx;
    final n = BleConnectionStateContext(this);
    _bleConnectionStateContexts[this] = n;
    return n;
  }

  /// Stream of MTU changes.
  Stream<int> get bleMtu => mtu;

  /// Reactive MTU context (cached per device).
  BleMtuContext bleMtuContext() {
    final ctx = _bleMtuContexts[this];
    if (ctx != null && !ctx.isDisposed) return ctx;
    final n = BleMtuContext(this);
    _bleMtuContexts[this] = n;
    return n;
  }

  /// Connect to a BLE device
  ///
  /// Parameters:
  /// - options: ConnectOptions including timeout, mtu, autoConnect, license
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

  /// Disconnect from a BLE device
  ///
  /// Parameters:
  /// - options: DisconnectOptions including timeout, queue, androidDelay
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

  /// Discover services for a connected device
  ///
  /// Parameters:
  /// - options: DiscoverServicesOptions
  ///
  /// Note: discoverServices must be re-called after every connection!
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

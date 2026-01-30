import 'dart:async';

import 'package:anyhow/anyhow.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart' as fbp;
import 'serialization.dart';
import 'webf.dart';
import 'options.dart';

extension BleDeviceExtensions on fbp.BluetoothDevice {
  /// Connect to a BLE device
  /// 
  /// Parameters:
  /// - options: ConnectOptions including timeout, mtu, autoConnect, license
  Future<Result<void>> bleConnect(ConnectOptions? options) async {
    final opts = options ?? const ConnectOptions();
    return guardAsync(() => connect(
      license: opts.license,
      timeout: opts.timeout,
      mtu: opts.mtu,
      autoConnect: opts.autoConnect,
    )).context('Failed to connect to device: ${remoteId.str}');
  }

  /// Disconnect from a BLE device
  /// 
  /// Parameters:
  /// - options: DisconnectOptions including timeout, queue, androidDelay
  Future<Result<void>> bleDisconnect(DisconnectOptions? options) async {
    final opts = options ?? const DisconnectOptions();
    return guardAsync(() => disconnect(
      timeout: opts.timeout,
      queue: opts.queue,
      androidDelay: opts.androidDelay,
    )).context('Failed to disconnect from device: ${remoteId.str}');
  }

  /// Discover services for a connected device
  /// 
  /// Parameters:
  /// - options: DiscoverServicesOptions
  /// 
  /// Note: discoverServices must be re-called after every connection!
  Future<Result<List<fbp.BluetoothService>>> bleDiscoverServices(DiscoverServicesOptions? options) async {
    final opts = options ?? const DiscoverServicesOptions();
    return guardAsync(() => discoverServices(
      subscribeToServicesChanged: opts.subscribeToServicesChanged,
      timeout: opts.timeout,
    )).context('Failed to discover services for device ${remoteId.str}');
  }
}

// ----------------------------------------------------------------------------
// Module Logic
// ----------------------------------------------------------------------------

Result<(String, Map<String, dynamic>?)> _parseDeviceArgs(List<dynamic> args, String methodName) {
  if (args.isEmpty) {
    return Err(Error('[BleModule] $methodName requires arguments'));
  }

  String? deviceId;
  Map<String, dynamic>? optionsMap;

  if (args[0] is String) {
    deviceId = args[0] as String;
    if (args.length > 1 && args[1] is Map) {
      optionsMap = args[1] as Map<String, dynamic>;
    }
  } else if (args[0] is Map) {
    final map = Map<String, dynamic>.from(args[0] as Map);
    deviceId = map.remove('deviceId') as String?;
    optionsMap = map.isEmpty ? null : map;
  }

  if (deviceId == null || deviceId.isEmpty) {
    return Err(Error('[BleModule] $methodName requires deviceId'));
  }

  return Ok((deviceId, optionsMap));
}


extension BleDeviceModule on BleWebfModule {
  /// Connect to a BLE device
  ///
  /// Arguments:
  /// - Option 1: [deviceId, {options?}]
  /// - Option 2: [{ deviceId: string, timeout?, mtu?, autoConnect? }]
  Future<Map<String, dynamic>> connect(List<dynamic> arguments) async {
    final parsed = _parseDeviceArgs(arguments, 'connect');
    if (parsed.isErr()) {
      return returnErr(parsed.unwrapErr().toString());
    }

    final (deviceId, optionsMap) = parsed.unwrap();
    final options = ConnectOptions.fromMap(optionsMap);
    final device = fbp.BluetoothDevice.fromId(deviceId);
    final result = await device.bleConnect(options);
    return result.toMap();
  }

  /// Disconnect from a BLE device
  ///
  /// Arguments:
  /// - Option 1: [deviceId, {options?}]
  /// - Option 2: [{ deviceId: string, timeout?, queue?, androidDelay? }]
  Future<Map<String, dynamic>> disconnect(List<dynamic> arguments) async {
    final parsed = _parseDeviceArgs(arguments, 'disconnect');
    if (parsed.isErr()) {
      return returnErr(parsed.unwrapErr().toString());
    }

    final (deviceId, optionsMap) = parsed.unwrap();
    final options = DisconnectOptions.fromMap(optionsMap);
    final device = fbp.BluetoothDevice.fromId(deviceId);
    final result = await device.bleDisconnect(options);
    return result.toMap();
  }

  /// Discover services for a connected device
  ///
  /// Arguments:
  /// - Option 1: [deviceId, {options?}]
  /// - Option 2: [{ deviceId: string, subscribeToServicesChanged?, timeout? }]
  Future<Map<String, dynamic>> discoverServices(List<dynamic> arguments) async {
    final parsed = _parseDeviceArgs(arguments, 'discoverServices');
    if (parsed.isErr()) {
      return returnErr(parsed.unwrapErr().toString());
    }

    final (deviceId, optionsMap) = parsed.unwrap();
    final options = DiscoverServicesOptions.fromMap(optionsMap);
    final device = fbp.BluetoothDevice.fromId(deviceId);
    final result = await device.bleDiscoverServices(options);
    return result.toMap((services) => services.toMap());
  }
}

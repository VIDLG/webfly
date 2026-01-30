import 'dart:async';

import 'package:anyhow/anyhow.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart' as fbp;
import 'serialization.dart';
import 'options.dart';
import 'webf.dart';

import '../../utils/stream_signal_context.dart';

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

extension BleCharacteristicExtensions on fbp.BluetoothCharacteristic {
  /// Stream of characteristic values (updated on read, write, notify)
  Stream<List<int>> get bleLastValueStream => lastValueStream;

  /// Reactive last value context
  BleLastValueContext get bleLastValueContext => 
      _bleLastValueContexts[this] ??= BleLastValueContext(this);

  /// Stream of incoming values (Read response or Notification)
  /// Does NOT include local writes or initial value.
  Stream<List<int>> get bleOnValueReceived => onValueReceived;

  /// Reactive on value received context
  BleOnValueReceivedContext get bleOnValueReceivedContext => 
      _bleOnValueReceivedContexts[this] ??= BleOnValueReceivedContext(this);


  /// Read a characteristic value
  Future<Result<List<int>>> bleRead(ReadCharacteristicOptions? options) async {
    final opts = options ?? const ReadCharacteristicOptions();
    return guardAsync(() => read(timeout: opts.timeout))
        .context('Failed to read characteristic $uuid (Device: ${remoteId.str})');
  }

  /// Write to a characteristic
  Future<Result<void>> bleWrite(List<int> data, WriteCharacteristicOptions? options) async {
    final opts = options ?? const WriteCharacteristicOptions();
    return guardAsync(() => write(
      data,
      withoutResponse: opts.withoutResponse,
      allowLongWrite: opts.allowLongWrite,
      timeout: opts.timeout,
    )).context('Failed to write characteristic $uuid (Device: ${remoteId.str})');
  }

  /// Enable/disable notifications for a characteristic
  Future<Result<void>> bleSetNotifyValue(bool enable, NotifyCharacteristicOptions? options) async {
    final opts = options ?? const NotifyCharacteristicOptions();
    return guardAsync(() => setNotifyValue(
      enable,
      timeout: opts.timeout,
      forceIndications: opts.forceIndications,
    )).context('Failed to set notify value for characteristic $uuid (Device: ${remoteId.str})');
  }
}

// ----------------------------------------------------------------------------
// Module Logic
// ----------------------------------------------------------------------------

Result<(String, String, String, Map<String, dynamic>?)> _parseCharacteristicArgs(List<dynamic> args, String methodName) {
  if (args.isEmpty) {
    return Err(Error('[BleModule] $methodName requires arguments'));
  }

  String? deviceId;
  String? serviceUuid;
  String? characteristicUuid;
  Map<String, dynamic>? map;

  if (args[0] is String) {
    if (args.length < 3) return Err(Error('[BleModule] $methodName requires at least 3 arguments (deviceId, serviceUuid, characteristicUuid)'));
    deviceId = args[0] as String;
    serviceUuid = args[1] as String;
    characteristicUuid = args[2] as String;
    if (args.length > 3 && args[3] is Map) {
      map = Map<String, dynamic>.from(args[3] as Map);
    }
  } else if (args[0] is Map) {
    map = Map<String, dynamic>.from(args[0] as Map);
    deviceId = map.remove('deviceId') as String?;
    serviceUuid = map.remove('serviceUuid') as String?;
    characteristicUuid = map.remove('characteristicUuid') as String?;
    if (map.isEmpty) {
      map = null;
    }
  }

  if (deviceId == null || serviceUuid == null || characteristicUuid == null) {
    return Err(Error('[BleModule] $methodName missing required UUIDs'));
  }

  return Ok((deviceId, serviceUuid, characteristicUuid, map));
}

Result<fbp.BluetoothCharacteristic> _findCharacteristic(String deviceId, String serviceUuid, String characteristicUuid) {
  final device = fbp.BluetoothDevice.fromId(deviceId);
  // Note: This logic assumes scan/discovery has happened or standard FBP pattern
  
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

extension BleCharacteristicModule on BleWebfModule {
  /// Read a characteristic value
  ///
  /// Arguments:
  /// - Option 1: [deviceId, serviceUuid, characteristicUuid, timeout?]
  /// - Option 2: [{ deviceId, serviceUuid, characteristicUuid, timeout? }]
  Future<Map<String, dynamic>> readCharacteristic(List<dynamic> arguments) async {
    final parsed = _parseCharacteristicArgs(arguments, 'readCharacteristic');
    if (parsed.isErr()) return returnErr(parsed.unwrapErr().toString());
    
    final (deviceId, serviceUuid, characteristicUuid, map) = parsed.unwrap();

    ReadCharacteristicOptions? options;
    if (map != null) {
      options = ReadCharacteristicOptions.fromMap(map);
    }

    final characteristicResult = _findCharacteristic(deviceId, serviceUuid, characteristicUuid);
    if (characteristicResult.isErr()) return returnErr(characteristicResult.unwrapErr().toString());
    final characteristic = characteristicResult.unwrap();

    final result = await characteristic.bleRead(options);
    return result.toMap();
  }

  /// Write to a characteristic
  /// Arguments: 
  /// - Option 1: [deviceId, serviceUuid, characteristicUuid, data, optionsMap?]
  /// - Option 2: [{ deviceId, serviceUuid, characteristicUuid, data, ...options }]
  Future<Map<String, dynamic>> writeCharacteristic(List<dynamic> arguments) async {
    final parsed = _parseCharacteristicArgs(arguments, 'writeCharacteristic');
    if (parsed.isErr()) return returnErr(parsed.unwrapErr().toString());

    final (deviceId, serviceUuid, characteristicUuid, map) = parsed.unwrap();
    
    if (map == null || map['data'] == null) return returnErr('writeCharacteristic requires data (in arguments[3] map or arguments[0] map)');
    final data = readList<int>(map['data']);
    final options = WriteCharacteristicOptions.fromMap(map);

    final characteristicResult = _findCharacteristic(deviceId, serviceUuid, characteristicUuid);
    if (characteristicResult.isErr()) return returnErr(characteristicResult.unwrapErr().toString());
    final characteristic = characteristicResult.unwrap();
    
    final result = await characteristic.bleWrite(data, options);
    return result.toMap();
  }

  /// Set Notify
  /// Arguments: 
  /// - Option 1: [deviceId, serviceUuid, characteristicUuid, enable, optionsMap?]
  /// - Option 2: [{ deviceId, serviceUuid, characteristicUuid, enable, ...options }]
  Future<Map<String, dynamic>> setNotifyValue(List<dynamic> arguments) async {
    final parsed = _parseCharacteristicArgs(arguments, 'setNotifyValue');
    if (parsed.isErr()) return returnErr(parsed.unwrapErr().toString());

    final (deviceId, serviceUuid, characteristicUuid, map) = parsed.unwrap();

    if (map == null || map['enable'] == null) return returnErr('setNotifyValue requires enable (in arguments[3] map or arguments[0] map)');
    final enable = map['enable'] as bool;
    final options = NotifyCharacteristicOptions.fromMap(map);

    final characteristicResult = _findCharacteristic(deviceId, serviceUuid, characteristicUuid);
    if (characteristicResult.isErr()) return returnErr(characteristicResult.unwrapErr().toString());
    final characteristic = characteristicResult.unwrap();

    final result = await characteristic.bleSetNotifyValue(enable, options);
    return result.toMap();
  }
}

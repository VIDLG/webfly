import 'dart:async';

import 'package:anyhow/anyhow.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart' as fbp;
import 'package:webf/webf.dart';

import '../native/ble/ble.dart';
import '../utils/app_logger.dart';
import 'protocol.dart';

// ---------------------------------------------------------------------------
// BLE event types (Dart side; matches ble.ts event payload types)
// ---------------------------------------------------------------------------

/// Event type names emitted to JS. Keep in sync with ble.ts BleEventType.
abstract final class BleEventType {
  static const connectionStateChanged = 'connectionStateChanged';
  static const characteristicReceived = 'characteristicReceived';
}

/// Payload for connectionStateChanged. Matches BleConnectionStateChangedData in ble.ts.
class BleConnectionStateChangedPayload {
  BleConnectionStateChangedPayload({
    required this.deviceId,
    required this.connectionState,
  });

  final String deviceId;
  final String connectionState;

  Map<String, dynamic> toJson() => {
    'deviceId': deviceId,
    'connectionState': connectionState,
  };
}

/// Payload for characteristicReceived. Matches BleCharacteristicReceivedData in ble.ts.
class BleCharacteristicReceivedPayload {
  BleCharacteristicReceivedPayload({
    required this.deviceId,
    required this.serviceUuid,
    required this.characteristicUuid,
    required this.value,
  });

  final String deviceId;
  final String serviceUuid;
  final String characteristicUuid;
  final List<int> value;

  Map<String, dynamic> toJson() => {
    'deviceId': deviceId,
    'serviceUuid': serviceUuid,
    'characteristicUuid': characteristicUuid,
    'value': value,
  };
}

// ---------------------------------------------------------------------------
// Module
// ---------------------------------------------------------------------------

/// WebF Native Module for Bluetooth Low Energy (BLE) operations
///
/// All WebF logic (invoke routing, argument parsing, BLE calls, response shaping)
/// is centralized here. adapter/device/characteristic expose only pure BLE APIs.
///
/// Events emitted to JS (listen via webf.on('Ble:eventName', (e) => e.detail)):
/// - connectionStateChanged: { deviceId, connectionState }
/// - characteristicReceived: { deviceId, serviceUuid, characteristicUuid, value }
class BleWebfModule extends WebFBaseModule {
  BleWebfModule(super.manager);

  StreamSubscription<fbp.OnConnectionStateChangedEvent>? _connectionStateSub;
  StreamSubscription<fbp.OnCharacteristicReceivedEvent>?
  _characteristicReceivedSub;

  @override
  String get name => 'Ble';

  @override
  Future<void> initialize() async {
    _connectionStateSub = BleEvents.onConnectionStateChanged.listen(
      _emitConnectionStateChanged,
    );
    _characteristicReceivedSub = BleEvents.onCharacteristicReceived.listen(
      _emitCharacteristicReceived,
    );
  }

  @override
  Future<dynamic> invoke(String method, List<dynamic> arguments) async {
    switch (method) {
      case 'isSupported':
        return _isSupported();
      case 'getAdapterState':
        return _getAdapterState();
      case 'turnOn':
        return _turnOn();
      case 'startScan':
        return _startScan(arguments);
      case 'stopScan':
        return _stopScan();
      case 'getScanResults':
        return _getScanResults();
      case 'isScanning':
        return _isScanning();
      case 'getConnectedDevices':
        return _getConnectedDevices();
      case 'connect':
        return _connect(arguments);
      case 'disconnect':
        return _disconnect(arguments);
      case 'discoverServices':
        return _discoverServices(arguments);
      case 'readCharacteristic':
        return _readCharacteristic(arguments);
      case 'writeCharacteristic':
        return _writeCharacteristic(arguments);
      case 'setNotifyValue':
        return _setNotifyValue(arguments);
      default:
        final error = '[BleModule] Unknown method: $method';
        appLogger.w(error);
        return returnErr(error, code: -32601);
    }
  }

  Future<dynamic> _isSupported() async {
    return returnOk(await bleIsSupported());
  }

  Future<dynamic> _getAdapterState() async {
    return returnOk(bleAdapterStateNow.toJson());
  }

  Future<dynamic> _turnOn() async {
    final result = await bleTurnOn();
    return result.toJson();
  }

  Future<dynamic> _startScan(List<dynamic> arguments) async {
    final map = arguments.isNotEmpty
        ? arguments[0] as Map<String, dynamic>?
        : null;
    final options = map == null
        ? const ScanOptions()
        : ScanOptions.fromJson(map);
    final result = await bleStartScan(options);
    return result.toJson();
  }

  Future<dynamic> _stopScan() async {
    final result = await bleStopScan();
    return result.toJson();
  }

  Future<dynamic> _getScanResults() async {
    return returnOk(
      bleLastScanResults.map((r) => ScanResultDto.fromFbp(r).toJson()).toList(),
    );
  }

  Future<dynamic> _isScanning() async {
    return returnOk(bleIsScanningNow);
  }

  Future<dynamic> _getConnectedDevices() async {
    return returnOk(
      bleConnectedDevices
          .map((d) => BluetoothDeviceDto.fromFbp(d).toJson())
          .toList(),
    );
  }

  Future<dynamic> _connect(List<dynamic> arguments) async {
    final parsed = _parseDeviceArgs(arguments, 'connect');
    if (parsed.isErr()) return returnErr(parsed.unwrapErr().toString());
    final (deviceId, optionsMap) = parsed.unwrap();
    final options = optionsMap == null
        ? const ConnectOptions()
        : ConnectOptions.fromJson(optionsMap);
    final device = fbp.BluetoothDevice.fromId(deviceId);
    final result = await device.bleConnect(options);
    return result.toJson();
  }

  Future<dynamic> _disconnect(List<dynamic> arguments) async {
    final parsed = _parseDeviceArgs(arguments, 'disconnect');
    if (parsed.isErr()) return returnErr(parsed.unwrapErr().toString());
    final (deviceId, optionsMap) = parsed.unwrap();
    final options = optionsMap == null
        ? const DisconnectOptions()
        : DisconnectOptions.fromJson(optionsMap);
    final device = fbp.BluetoothDevice.fromId(deviceId);
    final result = await device.bleDisconnect(options);
    return result.toJson();
  }

  Future<dynamic> _discoverServices(List<dynamic> arguments) async {
    final parsed = _parseDeviceArgs(arguments, 'discoverServices');
    if (parsed.isErr()) return returnErr(parsed.unwrapErr().toString());
    final (deviceId, optionsMap) = parsed.unwrap();
    final options = optionsMap == null
        ? const DiscoverServicesOptions()
        : DiscoverServicesOptions.fromJson(optionsMap);
    final device = fbp.BluetoothDevice.fromId(deviceId);
    final result = await device.bleDiscoverServices(options);
    return result.toJson(
      (services) =>
          services.map((s) => BluetoothServiceDto.fromFbp(s).toJson()).toList(),
    );
  }

  Future<dynamic> _readCharacteristic(List<dynamic> arguments) async {
    final parsed = _parseCharacteristicArgs(arguments, 'readCharacteristic');
    if (parsed.isErr()) return returnErr(parsed.unwrapErr().toString());
    final (deviceId, serviceUuid, characteristicUuid, map) = parsed.unwrap();
    final options = map == null
        ? null
        : ReadCharacteristicOptions.fromJson(map);
    final cResult = bleFindCharacteristic(
      deviceId,
      serviceUuid,
      characteristicUuid,
    );
    if (cResult.isErr()) {
      return returnErr(cResult.unwrapErr().toString());
    }
    final result = await cResult.unwrap().bleRead(options);
    return result.toJson();
  }

  Future<dynamic> _writeCharacteristic(List<dynamic> arguments) async {
    if (arguments.length < 4) {
      return returnErr(
        'writeCharacteristic requires [deviceId, serviceUuid, characteristicUuid, data, options?]',
      );
    }
    if (arguments[3] is! List) {
      return returnErr('writeCharacteristic data (args[3]) must be number[]');
    }
    final deviceId = arguments[0] as String;
    final serviceUuid = arguments[1] as String;
    final characteristicUuid = arguments[2] as String;
    final data = (arguments[3] as List)
        .map((e) => e is int ? e : (e is num ? e.toInt() : null))
        .whereType<int>()
        .toList();
    final optionsMap = arguments.length > 4 && arguments[4] is Map
        ? Map<String, dynamic>.from(arguments[4] as Map)
        : null;
    final options = optionsMap == null
        ? const WriteCharacteristicOptions()
        : WriteCharacteristicOptions.fromJson(optionsMap);
    final cResult = bleFindCharacteristic(
      deviceId,
      serviceUuid,
      characteristicUuid,
    );
    if (cResult.isErr()) {
      return returnErr(cResult.unwrapErr().toString());
    }
    final result = await cResult.unwrap().bleWrite(data, options);
    return result.toJson();
  }

  Future<dynamic> _setNotifyValue(List<dynamic> arguments) async {
    if (arguments.length < 4) {
      return returnErr(
        'setNotifyValue requires [deviceId, serviceUuid, characteristicUuid, enable, options?]',
      );
    }
    if (arguments[3] is! bool) {
      return returnErr('setNotifyValue enable (args[3]) must be boolean');
    }
    final deviceId = arguments[0] as String;
    final serviceUuid = arguments[1] as String;
    final characteristicUuid = arguments[2] as String;
    final enable = arguments[3] as bool;
    final optionsMap = arguments.length > 4 && arguments[4] is Map
        ? Map<String, dynamic>.from(arguments[4] as Map)
        : null;
    final options = optionsMap == null
        ? const NotifyCharacteristicOptions()
        : NotifyCharacteristicOptions.fromJson(optionsMap);
    final cResult = bleFindCharacteristic(
      deviceId,
      serviceUuid,
      characteristicUuid,
    );
    if (cResult.isErr()) {
      return returnErr(cResult.unwrapErr().toString());
    }
    final result = await cResult.unwrap().bleSetNotifyValue(enable, options);
    return result.toJson();
  }

  // ---------------------------------------------------------------------------
  // Argument parsing (JS call shapes)
  // ---------------------------------------------------------------------------

  /// Parses [deviceId, options?] (positional only).
  Result<(String, Map<String, dynamic>?)> _parseDeviceArgs(
    List<dynamic> args,
    String methodName,
  ) {
    if (args.isEmpty || args[0] is! String) {
      return Err(
        Error('[BleModule] $methodName requires [deviceId, options?]'),
      );
    }
    final deviceId = args[0] as String;
    if (deviceId.isEmpty) {
      return Err(Error('[BleModule] $methodName requires deviceId'));
    }
    final optionsMap = args.length > 1 && args[1] is Map
        ? Map<String, dynamic>.from(args[1] as Map)
        : null;
    return Ok((deviceId, optionsMap));
  }

  /// Parses [deviceId, serviceUuid, characteristicUuid, options?] (positional only).
  Result<(String, String, String, Map<String, dynamic>?)>
  _parseCharacteristicArgs(List<dynamic> args, String methodName) {
    if (args.length < 3) {
      return Err(
        Error(
          '[BleModule] $methodName requires [deviceId, serviceUuid, characteristicUuid, options?]',
        ),
      );
    }
    if (args[0] is! String || args[1] is! String || args[2] is! String) {
      return Err(
        Error(
          '[BleModule] $methodName requires deviceId, serviceUuid, characteristicUuid as strings',
        ),
      );
    }
    final deviceId = args[0] as String;
    final serviceUuid = args[1] as String;
    final characteristicUuid = args[2] as String;
    final map = args.length > 3 && args[3] is Map
        ? Map<String, dynamic>.from(args[3] as Map)
        : null;
    return Ok((deviceId, serviceUuid, characteristicUuid, map));
  }

  void _emitConnectionStateChanged(fbp.OnConnectionStateChangedEvent event) {
    try {
      final payload = BleConnectionStateChangedPayload(
        deviceId: event.device.remoteId.str,
        connectionState: event.connectionState.name,
      );
      dispatchEvent(
        event: Event(BleEventType.connectionStateChanged),
        data: payload.toJson(),
      );
    } catch (e) {
      appLogger.w('[BleModule] connectionStateChanged emit error: $e');
    }
  }

  void _emitCharacteristicReceived(fbp.OnCharacteristicReceivedEvent event) {
    try {
      final payload = BleCharacteristicReceivedPayload(
        deviceId: event.characteristic.remoteId.str,
        serviceUuid: event.characteristic.serviceUuid.toString(),
        characteristicUuid: event.characteristic.uuid.toString(),
        value: event.value,
      );
      dispatchEvent(
        event: Event(BleEventType.characteristicReceived),
        data: payload.toJson(),
      );
    } catch (e) {
      appLogger.w('[BleModule] characteristicReceived emit error: $e');
    }
  }

  @override
  void dispose() {
    _connectionStateSub?.cancel();
    _connectionStateSub = null;
    _characteristicReceivedSub?.cancel();
    _characteristicReceivedSub = null;
  }
}

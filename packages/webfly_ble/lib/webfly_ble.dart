// Re-export flutter_blue_plus, wrappers, options, DTOs, and WebF BLE module.
// Usage: import 'package:webfly_ble/webfly_ble.dart'; or show BleWebfModule for WebF only.

export 'package:flutter_blue_plus/flutter_blue_plus.dart';
export 'src/adapter.dart';
export 'src/characteristic.dart';
export 'src/device.dart';
export 'src/dto.dart';
export 'src/options.dart';

import 'dart:async';

import 'package:anyhow/anyhow.dart';
import 'package:flutter/foundation.dart';
import 'package:webf/webf.dart';
import 'package:webf_bridge/webf_bridge.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:webfly_ble/src/adapter.dart';
import 'package:webfly_ble/src/characteristic.dart';
import 'package:webfly_ble/src/device.dart';
import 'package:webfly_ble/src/dto.dart';
import 'package:webfly_ble/src/options.dart';

// ---------------------------------------------------------------------------
// BLE event types (Dart side; matches ble.ts event payload types)
// ---------------------------------------------------------------------------

abstract final class BleEventType {
  static const connectionStateChanged = 'connectionStateChanged';
  static const characteristicReceived = 'characteristicReceived';
}

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

class BleWebfModule extends WebFBaseModule {
  BleWebfModule(super.manager);

  StreamSubscription<OnConnectionStateChangedEvent>? _connectionStateSub;
  StreamSubscription<OnCharacteristicReceivedEvent>? _characteristicReceivedSub;

  @override
  String get name => 'Ble';

  @override
  Future<void> initialize() async {
    _connectionStateSub =
        FlutterBluePlus.events.onConnectionStateChanged.listen(
      _emitConnectionStateChanged,
    );
    _characteristicReceivedSub =
        FlutterBluePlus.events.onCharacteristicReceived.listen(
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
        debugPrint('[webfly_ble] $error');
        return webfErr(error);
    }
  }

  Future<dynamic> _isSupported() async {
    return webfOk(await FlutterBluePlus.isSupported);
  }

  Future<dynamic> _getAdapterState() async {
    return webfOk(FlutterBluePlus.adapterStateNow.name);
  }

  Future<dynamic> _turnOn() async {
    final result = await bleTurnOn();
    return result.toWebfJson();
  }

  Future<dynamic> _startScan(List<dynamic> arguments) async {
    final map = arguments.isNotEmpty
        ? arguments[0] as Map<String, dynamic>?
        : null;
    final options = map == null
        ? const ScanOptions()
        : ScanOptions.fromJson(map);
    final result = await bleStartScan(options);
    return result.toWebfJson();
  }

  Future<dynamic> _stopScan() async {
    final result = await bleStopScan();
    return result.toWebfJson();
  }

  Future<dynamic> _getScanResults() async {
    return webfOk(
      FlutterBluePlus.lastScanResults
          .map((r) => ScanResultDto.fromFbp(r).toJson())
          .toList(),
    );
  }

  Future<dynamic> _isScanning() async {
    return webfOk(FlutterBluePlus.isScanningNow);
  }

  Future<dynamic> _getConnectedDevices() async {
    return webfOk(
      FlutterBluePlus.connectedDevices
          .map((d) => BluetoothDeviceDto.fromFbp(d).toJson())
          .toList(),
    );
  }

  Future<dynamic> _connect(List<dynamic> arguments) async {
    final parsed = _parseDeviceArgs(arguments, 'connect');
    if (parsed.isErr()) return webfErr(parsed.unwrapErr().toString());
    final (deviceId, optionsMap) = parsed.unwrap();
    final options = optionsMap == null
        ? const ConnectOptions()
        : ConnectOptions.fromJson(optionsMap);
    final device = BluetoothDevice.fromId(deviceId);
    final result = await device.bleConnect(options);
    return result.toWebfJson();
  }

  Future<dynamic> _disconnect(List<dynamic> arguments) async {
    final parsed = _parseDeviceArgs(arguments, 'disconnect');
    if (parsed.isErr()) return webfErr(parsed.unwrapErr().toString());
    final (deviceId, optionsMap) = parsed.unwrap();
    final options = optionsMap == null
        ? const DisconnectOptions()
        : DisconnectOptions.fromJson(optionsMap);
    final device = BluetoothDevice.fromId(deviceId);
    final result = await device.bleDisconnect(options);
    return result.toWebfJson();
  }

  Future<dynamic> _discoverServices(List<dynamic> arguments) async {
    final parsed = _parseDeviceArgs(arguments, 'discoverServices');
    if (parsed.isErr()) return webfErr(parsed.unwrapErr().toString());
    final (deviceId, optionsMap) = parsed.unwrap();
    final options = optionsMap == null
        ? const DiscoverServicesOptions()
        : DiscoverServicesOptions.fromJson(optionsMap);
    final device = BluetoothDevice.fromId(deviceId);
    final result = await device.bleDiscoverServices(options);
    return result.toWebfJson((services) {
      return services.map((s) => BluetoothServiceDto.fromFbp(s).toJson()).toList();
    });
  }

  Future<dynamic> _readCharacteristic(List<dynamic> arguments) async {
    final parsed = _parseCharacteristicArgs(arguments, 'readCharacteristic');
    if (parsed.isErr()) return webfErr(parsed.unwrapErr().toString());
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
      return webfErr(cResult.unwrapErr().toString());
    }
    final result = await cResult.unwrap().bleRead(options);
    return result.toWebfJson();
  }

  Future<dynamic> _writeCharacteristic(List<dynamic> arguments) async {
    if (arguments.length < 4) {
      return webfErr(
        'writeCharacteristic requires [deviceId, serviceUuid, characteristicUuid, data, options?]',
      );
    }
    if (arguments[3] is! List) {
      return webfErr('writeCharacteristic data (args[3]) must be number[]');
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
      return webfErr(cResult.unwrapErr().toString());
    }
    final result = await cResult.unwrap().bleWrite(data, options);
    return result.toWebfJson();
  }

  Future<dynamic> _setNotifyValue(List<dynamic> arguments) async {
    if (arguments.length < 4) {
      return webfErr(
        'setNotifyValue requires [deviceId, serviceUuid, characteristicUuid, enable, options?]',
      );
    }
    if (arguments[3] is! bool) {
      return webfErr('setNotifyValue enable (args[3]) must be boolean');
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
      return webfErr(cResult.unwrapErr().toString());
    }
    final result = await cResult.unwrap().bleSetNotifyValue(enable, options);
    return result.toWebfJson();
  }

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

  void _emitConnectionStateChanged(OnConnectionStateChangedEvent event) {
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
      debugPrint('[webfly_ble] connectionStateChanged emit error: $e');
    }
  }

  void _emitCharacteristicReceived(OnCharacteristicReceivedEvent event) {
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
      debugPrint('[webfly_ble] characteristicReceived emit error: $e');
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

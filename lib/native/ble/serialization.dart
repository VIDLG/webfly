import 'package:anyhow/anyhow.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart' as fbp;

// ============================================================================
// Protocol Helpers
// ============================================================================

/// Helper to create a success map response
Map<String, dynamic> returnOk(dynamic result) => {
  'result': result,
};

/// Helper to create an error map response
/// Code -32603 signifies 'Internal error' in JSON-RPC 2.0
Map<String, dynamic> returnErr(String message, {int code = -32603}) => {
  'error': {
    'code': code,
    'message': message,
  },
};

/// Helper to read a list safely from a dynamic value (usually from JSON/Map)
/// Any item that returns null from [converter] will be filtered out.
/// If [converter] is null, items that do not match type [T] are filtered out.
List<T> readList<T>(dynamic value, [T? Function(dynamic)? converter]) {
  if (value is! List) return <T>[];
  return value
      .map((e) {
        if (converter != null) return converter(e);
        return e is T ? e : null;
      })
      .where((e) => e != null)
      .cast<T>()
      .toList();
}

/// Helper to read a duration from a dynamic value
/// [unit] is the multiplier for the value to convert to milliseconds.
/// Defaults to 1000 (seconds).
Duration? readDuration(dynamic value, {int unit = 1000}) {
  return value != null ? Duration(milliseconds: (value as int) * unit) : null;
}

// ============================================================================
// Core Type Serializations
// ============================================================================

/// Generic Result serialization
extension ResultSerialization<S> on Result<S> {
  /// Serialize Result to Map
  /// 
  /// Returns:
  /// - Success: {'jsonrpc': '2.0', 'result': value}
  /// - Failure: {'jsonrpc': '2.0', 'error': {'code': -32603, 'message': errorString}}
  /// 
  /// If [mapper] is provided, it will be used to transform the success value.
  Map<String, dynamic> toMap([dynamic Function(S s)? mapper]) {
    return match(
      ok: (value) => returnOk(mapper != null ? mapper(value) : value),
      err: (error) => returnErr(error.toString()),
    );
  }
}

/// Generic enum serialization
///
/// By default we serialize enums using their name (e.g. BluetoothAdapterState.on -> 'on').
/// This keeps JSON payloads stable and avoids toString() prefixes like Type.value.
extension EnumSerialization on Enum {
  String toMap() => name;
}

/// Device identifier serialization
extension DeviceIdentifierSerialization on fbp.DeviceIdentifier {
  /// Serialize to string
  ///
  /// Uses the underlying identifier string.
  String toMap() => str;
}

/// BLE Guid (UUID) serialization
extension GuidSerialization on fbp.Guid {
  /// Serialize to string
  ///
  /// Uses the shortest representation (16/32-bit stay short), matching toString().
  String toMap() => str;
}

// ============================================================================
// Scanning Serializations
// ============================================================================

/// Extension for AdvertisementData serialization
extension AdvertisementDataSerialization on fbp.AdvertisementData {
  /// Serialize to Map
  /// 
  /// Returns a map with advertisement data:
  /// - advName: string
  /// - txPowerLevel: number | null
  /// - appearance: number | null
  /// - connectable: boolean
  /// - manufacturerData: `Map<string, List<int>>` (key is stringified int)
  /// - serviceData: `Map<string, List<int>>` (key is UUID string)
  /// - serviceUuids: `List<string>`
  Map<String, dynamic> toMap() {
    return {
      'advName': advName,
      'txPowerLevel': txPowerLevel,
      'appearance': appearance,
      'connectable': connectable,
      'manufacturerData': manufacturerData.map(
        (key, value) => MapEntry(key.toString(), value),
      ),
      'serviceData': serviceData.map(
        (key, value) => MapEntry(key.toMap(), value),
      ),
      'serviceUuids': serviceUuids.map((uuid) => uuid.toMap()).toList(),
    };
  }
}

/// Extension for ScanResult serialization
extension ScanResultSerialization on fbp.ScanResult {
  /// Serialize to Map
  /// 
  /// Returns a map with scan result information:
  /// - remoteId: string
  /// - rssi: number
  /// - advertisementData: Map with advertisement data
  /// - timestamp: int (milliseconds since epoch)
  Map<String, dynamic> toMap() {
    return {
      'remoteId': device.remoteId.toMap(),
      'rssi': rssi,
      'advertisementData': advertisementData.toMap(),
      'timestamp_ms': timeStamp.millisecondsSinceEpoch,
    };
  }
}

/// Extension for List of ScanResult serialization
extension ScanResultListSerialization on List<fbp.ScanResult> {
  /// Serialize list to List of Maps
  List<Map<String, dynamic>> toMap() {
    return map((result) => result.toMap()).toList();
  }
}

// ============================================================================
// Device & Connection Serialization
// ============================================================================

/// Extension for BluetoothDevice serialization
extension BluetoothDeviceSerialization on fbp.BluetoothDevice {
  /// Serialize to Map
  /// 
  /// Returns a map with device information:
  /// - remoteId: string
  /// - platformName: string
  /// - advName: string (advertised name)
  /// - isConnected: boolean
  /// - mtuNow: int (current MTU size)
  Map<String, dynamic> toMap() {
    return {
      'remoteId': remoteId.toMap(),
      'platformName': platformName,
      'advName': advName,
      'isConnected': isConnected,
      'mtuNow': mtuNow,
    };
  }
}

/// Extension for List of BluetoothDevice serialization
extension BluetoothDeviceListSerialization on List<fbp.BluetoothDevice> {
  /// Serialize list to List of Maps
  List<Map<String, dynamic>> toMap() {
    return map((device) => device.toMap()).toList();
  }
}

/// Extension for Map of deviceId -> BluetoothConnectionState serialization
extension BluetoothConnectionStateMapSerialization on Map<String, fbp.BluetoothConnectionState> {
  /// Serialize Map to Map of deviceId -> string
  Map<String, String> toMap() {
    return map((key, value) => MapEntry(key, value.toMap()));
  }
}

/// Extension for DisconnectReason serialization
extension DisconnectReasonSerialization on fbp.DisconnectReason {
  /// Serialize to Map
  ///
  /// Keys are kept stable for JS/native bridges.
  /// - platform: string
  /// - code: number | null
  /// - description: string | null
  Map<String, dynamic> toMap() {
    return {
      'platform': platform.toMap(),
      'code': code,
      'description': description,
    };
  }
}

// ============================================================================
// GATT (Service, Characteristic, Descriptor) Serialization
// ============================================================================

/// Extension for BluetoothService serialization
extension BluetoothServiceSerialization on fbp.BluetoothService {
  Map<String, dynamic> toMap() => {
    'uuid': serviceUuid.toMap(),
    'remoteId': remoteId.toMap(),
    'primaryServiceUuid': primaryServiceUuid?.toMap(),
    'characteristics': characteristics.map((c) => c.toMap()).toList(),
  };
}

extension ServiceListSerialization on List<fbp.BluetoothService> {
  List<Map<String, dynamic>> toMap() => map((e) => e.toMap()).toList();
}


/// Extension for BluetoothCharacteristic serialization
extension BluetoothCharacteristicSerialization on fbp.BluetoothCharacteristic {
  Map<String, dynamic> toMap() => {
    'uuid': uuid.toMap(),
    'remoteId': remoteId.toMap(),
    'serviceUuid': serviceUuid.toMap(),
    // 'secondaryServiceUuid': secondaryServiceUuid?.toMap(), // Remove if undefined in your FBP version
    'properties': properties.toMap(),
    'descriptors': descriptors.map((d) => d.toMap()).toList(),
    'isNotifying': isNotifying,
    'lastValue': lastValue,
  };
}

/// Extension for CharacteristicProperties serialization
extension CharacteristicPropertiesSerialization on fbp.CharacteristicProperties {
  Map<String, dynamic> toMap() => {
    'broadcast': broadcast,
    'read': read,
    'writeWithoutResponse': writeWithoutResponse,
    'write': write,
    'notify': notify,
    'indicate': indicate,
    'authenticatedSignedWrites': authenticatedSignedWrites,
    'extendedProperties': extendedProperties,
    'notifyEncryptionRequired': notifyEncryptionRequired,
    'indicateEncryptionRequired': indicateEncryptionRequired,
  };
}

/// Extension for BluetoothDescriptor serialization
extension BluetoothDescriptorSerialization on fbp.BluetoothDescriptor {
  Map<String, dynamic> toMap() => {
    'uuid': descriptorUuid.toMap(),
    'remoteId': remoteId.toMap(),
    'serviceUuid': serviceUuid.toMap(),
    'characteristicUuid': characteristicUuid.toMap(),
    'primaryServiceUuid': primaryServiceUuid?.toMap(), // Added
    'lastValue': lastValue,
  };
}

import 'package:anyhow/anyhow.dart';

// ============================================================================
// Protocol Helpers (JSON-RPC style response for WebF native modules)
// ============================================================================

/// Helper to create a success map response
Map<String, dynamic> returnOk(dynamic result) => {'result': result};

/// Helper to create an error map response
/// Code -32603 signifies 'Internal error' in JSON-RPC 2.0
Map<String, dynamic> returnErr(String message, {int code = -32603}) => {
  'error': {'code': code, 'message': message},
};

// ============================================================================
// Core Type Serializations
// ============================================================================

/// Generic Result serialization
extension ResultSerialization<S> on Result<S> {
  /// Serialize Result to Map
  ///
  /// Returns:
  /// - Success: {'result': value}
  /// - Failure: {'error': {'code': -32603, 'message': errorString}}
  ///
  /// If [mapper] is provided, it will be used to transform the success value.
  Map<String, dynamic> toJson([dynamic Function(S s)? mapper]) {
    return match(
      ok: (value) => returnOk(mapper != null ? mapper(value) : value),
      err: (error) => returnErr(error.toString()),
    );
  }
}

/// Generic enum serialization
///
/// Serialize enums using their name (e.g. BluetoothAdapterState.on -> 'on').
/// Keeps JSON payloads stable and avoids toString() prefixes like Type.value.
extension EnumSerialization on Enum {
  String toJson() => name;
}

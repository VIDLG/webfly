// Shared WebF bridge (Dart). Wire format for TS: { type: 'ok', value: T } | { type: 'err', message: string }.
// Usage: import 'package:webf_bridge/webf_bridge.dart';

import 'package:anyhow/anyhow.dart';

/// Success payload for WebF TS: { type: 'ok', value: value }.
Map<String, dynamic> webfOk(dynamic value) => {'type': 'ok', 'value': value};

/// Error payload for WebF TS: { type: 'err', message: message }.
Map<String, dynamic> webfErr(String message) => {'type': 'err', 'message': message};

/// Converts [Result] to WebF response map. Optional [mapper] to serialize the success value.
extension ResultToWebfJson<S> on Result<S> {
  Map<String, dynamic> toWebfJson([dynamic Function(S s)? mapper]) {
    return match(
      ok: (value) => webfOk(mapper != null ? mapper(value) : value),
      err: (e) => webfErr(e.toString()),
    );
  }
}

# webfly_ble

Flutter BLE wrapper around [flutter_blue_plus](https://pub.dev/packages/flutter_blue_plus), designed for reuse across projects.

## Usage

Add as a dependency (path or published):

```yaml
dependencies:
  webfly_ble:
    path: ../packages/webfly_ble  # or your path
```

Import the barrel:

```dart
import 'package:webfly_ble/webfly_ble.dart';
```

## API overview

- **Adapter**: `bleTurnOn()`, `bleStartScan(ScanOptions?)`, `bleStopScan()` (all return `Result`). Use `FlutterBluePlus.*` for isSupported, adapterState, scanResults, etc.
- **Device** (extension on `BluetoothDevice`): `bleConnect`, `bleDisconnect`, `bleDiscoverServices`. Use FBP’s `connectionState` / `mtu` for streams.
- **Characteristic** (extension on `BluetoothCharacteristic`): `bleRead`, `bleWrite`, `bleSetNotifyValue`. Use FBP’s `lastValueStream` / `onValueReceived` for streams.
- **Helpers**: `bleFindCharacteristic(deviceId, serviceUuid, characteristicUuid)`.
- **DTOs**: `ScanResultDto`, `BluetoothDeviceDto`, `BluetoothServiceDto`, etc. (JSON-serializable).
- **Options**: `ScanOptions`, `ConnectOptions`, `DisconnectOptions`, `DiscoverServicesOptions`, `ReadCharacteristicOptions`, `WriteCharacteristicOptions`, `NotifyCharacteristicOptions`.
- **WebF (optional)**: `import 'package:webfly_ble/webfly_ble.dart' show BleWebfModule;` then `WebF.defineModule((context) => BleWebfModule(context))`. TS API: `lib/webf_ble.ts` — alias `@native/webf/ble` to `packages/webfly_ble/lib/webf_ble`.

All async BLE operations return `Result<T>` from [anyhow](https://pub.dev/packages/anyhow).

## Code generation

`build_runner` is in this package’s `dev_dependencies`. After changing DTOs or options (e.g. add `@JsonKey`):

- **From this package:** `just codegen` or `dart run build_runner build --delete-conflicting-outputs`
- **From repo root (webfly):** `just codegen` runs build_runner in root and in this package.

## Publishing (self-managed in this package)

Scripts are in this directory’s **justfile**. Run from `packages/webfly_ble`:

| Command | Description |
|--------|-------------|
| `just codegen` | Generate dto.g.dart, options.g.dart |
| `just test` | Run tests |
| `just publish-dry-run` | Validate package for pub.dev (no upload) |
| `just publish` | Publish to pub.dev |

Before first publish: remove or change `publish_to: none` in `pubspec.yaml`, then `dart pub login`. Bump version in `pubspec.yaml` manually; update `CHANGELOG.md` per release.

## License

Same as the parent project.

// Barrel: export all BLE APIs so callers import from one place.
//
// Symbols (from which file):
//   adapter.dart      -> bleIsSupported, bleAdapterStateNow, bleTurnOn, bleStartScan, bleStopScan, bleLastScanResults, bleIsScanningNow, bleConnectedDevices
//   characteristic.dart -> bleFindCharacteristic
//   device.dart       -> BluetoothDevice.bleConnect, bleDisconnect, bleDiscoverServices; BluetoothCharacteristic.bleRead, bleWrite, bleSetNotifyValue
//   dto.dart          -> ScanResultDto, BluetoothDeviceDto, BluetoothServiceDto, ...
//   events.dart       -> BLE streams/events
//   options.dart      -> ScanOptions, ConnectOptions, DisconnectOptions, DiscoverServicesOptions, ReadCharacteristicOptions, WriteCharacteristicOptions, NotifyCharacteristicOptions

export 'adapter.dart';
export 'characteristic.dart';
export 'device.dart';
export 'dto.dart';
export 'events.dart';
export 'options.dart';

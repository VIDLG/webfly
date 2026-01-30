import 'package:webf/webf.dart';
import '../../utils/app_logger.dart';
import 'serialization.dart';
import 'adapter.dart';
import 'device.dart';
import 'characteristic.dart';

/// WebF Native Module for Bluetooth Low Energy (BLE) operations
///
/// Provides JavaScript API for scanning, connecting, and communicating with BLE devices.
class BleWebfModule extends WebFBaseModule {
  BleWebfModule(super.manager);

  @override
  String get name => 'Ble';

  @override
  Future<dynamic> invoke(String method, List<dynamic> arguments) async {
    switch (method) {
      case 'isSupported':
        return await isSupported();
      case 'getAdapterState':
        return await getAdapterState();
      case 'turnOn':
        return await turnOn();
      case 'startScan':
        return await startScan(arguments);
      case 'stopScan':
        return await stopScan();
      case 'getScanResults':
        return await getScanResults();
      case 'isScanning':
        return await isScanning();
      case 'getConnectedDevices':
        return await getConnectedDevices();
      case 'connect':
        return await connect(arguments);
      case 'disconnect':
        return await disconnect(arguments);
      case 'discoverServices':
        return await discoverServices(arguments);
      case 'readCharacteristic':
        return await readCharacteristic(arguments);
      case 'writeCharacteristic':
        return await writeCharacteristic(arguments);
      case 'setNotifyValue':
        return await setNotifyValue(arguments);
      default:
        final error = '[BleModule] Unknown method: $method';
        appLogger.w(error);
        return returnErr(error, code: -32601); // -32601: Method not found
    }
  }

  @override
  void dispose() {
    // No cleanup needed - FlutterBluePlus manages its own state
  }
}

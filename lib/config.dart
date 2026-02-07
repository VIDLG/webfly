// Global application configuration constants

// WebF timeout configuration
/// Default timeout for controller loading operations.
///
/// This is the maximum time to wait for a WebF controller to be created
/// and initialized. If exceeded, a timeout error will be reported.
const Duration kDefaultControllerLoadingTimeout = Duration(seconds: 15);

/// Default timeout for hybrid route resolution.
///
/// When deep-linking to a route other than '/', this timeout controls
/// how long to wait for the frontend router to register the route before
/// giving up and showing an error.
const Duration kDefaultHybridRouteResolutionTimeout = Duration(seconds: 10);

/// Default polling interval for checking hybrid route resolution.
///
/// When waiting for a hybrid route to be resolvable, this controls
/// how frequently to check if the route is ready.
const Duration kDefaultHybridRoutePollInterval = Duration(milliseconds: 50);

// BLE configuration
/// Timeout for BLE scanning operations.
///
/// This is the scan duration when no timeout is specified.
const Duration kBleScanTimeout = Duration(seconds: 15);

/// License for BLE device connections.
///
/// This license is used when connecting to BLE devices.
/// Options: 'free' or 'commercial'
const String kBleLicense = 'free';

/// Timeout for BLE device connections.
///
/// This is the connection timeout when connecting to BLE devices.
const Duration kBleConnectTimeout = Duration(seconds: 35);

/// MTU (Maximum Transmission Unit) for BLE device connections.
///
/// This is the MTU size when connecting to BLE devices.
const int kBleMtu = 512;

/// Timeout for BLE device disconnections (in seconds).
///
/// This is the disconnection timeout when disconnecting from BLE devices.
const int kBleDisconnectTimeout = 35;

/// Queue option for BLE device disconnections.
///
/// If true, the disconnect operation will be queued if the device is currently connecting.
const bool kBleDisconnectQueue = true;

/// Android delay for BLE device disconnections (in milliseconds).
///
/// Delay before disconnecting on Android platform.
const int kBleDisconnectAndroidDelay = 2000;

/// Timeout for BLE service discovery operations (in seconds).
///
/// This is the timeout when discovering services on a connected BLE device.
const int kBleDiscoverServicesTimeout = 15;

/// Subscribe to services changed option for BLE service discovery.
///
/// Android & Linux Only: If true, after discovering services we will subscribe to the
/// Services Changed Characteristic (0x2A05) used for the device.onServicesReset stream.
/// Note: this behavior happens automatically on iOS and cannot be disabled.
const bool kBleDiscoverServicesSubscribeToServicesChanged = true;

/// Timeout for BLE characteristic read operations (in seconds).
///
/// This is the timeout when reading a characteristic value.
const int kBleReadCharacteristicTimeout = 15;

/// Timeout for BLE characteristic write operations (in seconds).
///
/// This is the timeout when writing a characteristic value.
const int kBleWriteCharacteristicTimeout = 15;

/// Timeout for BLE characteristic set notify operations (in seconds).
///
/// This is the timeout when enabling/disabling notifications for a characteristic.
const int kBleSetNotifyValueTimeout = 15;

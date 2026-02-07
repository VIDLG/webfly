import 'package:permission_handler/permission_handler.dart';
import 'package:webf/webf.dart';

import '../utils/app_logger.dart';
import 'protocol.dart';

/// Maps a permission name string (from JS) to [Permission].
/// Supports camelCase names matching permission_handler constants.
Permission? _permissionFromName(String name) {
  switch (name) {
    case 'camera':
      return Permission.camera;
    case 'microphone':
      return Permission.microphone;
    case 'bluetooth':
      return Permission.bluetooth;
    case 'bluetoothScan':
      return Permission.bluetoothScan;
    case 'bluetoothConnect':
      return Permission.bluetoothConnect;
    case 'bluetoothAdvertise':
      return Permission.bluetoothAdvertise;
    case 'location':
      return Permission.location;
    case 'locationWhenInUse':
      return Permission.locationWhenInUse;
    case 'locationAlways':
      return Permission.locationAlways;
    case 'notification':
      return Permission.notification;
    case 'photos':
      return Permission.photos;
    case 'photosAddOnly':
      return Permission.photosAddOnly;
    case 'storage':
      return Permission.storage;
    case 'manageExternalStorage':
      return Permission.manageExternalStorage;
    case 'contacts':
      return Permission.contacts;
    case 'calendarFullAccess':
      return Permission.calendarFullAccess;
    case 'calendarWriteOnly':
      return Permission.calendarWriteOnly;
    case 'sms':
      return Permission.sms;
    case 'phone':
      return Permission.phone;
    case 'mediaLibrary':
      return Permission.mediaLibrary;
    case 'speech':
      return Permission.speech;
    case 'sensors':
      return Permission.sensors;
    case 'sensorsAlways':
      return Permission.sensorsAlways;
    case 'ignoreBatteryOptimizations':
      return Permission.ignoreBatteryOptimizations;
    case 'activityRecognition':
      return Permission.activityRecognition;
    case 'reminders':
      return Permission.reminders;
    case 'criticalAlerts':
      return Permission.criticalAlerts;
    case 'appTrackingTransparency':
      return Permission.appTrackingTransparency;
    case 'systemAlertWindow':
      return Permission.systemAlertWindow;
    case 'requestInstallPackages':
      return Permission.requestInstallPackages;
    case 'scheduleExactAlarm':
      return Permission.scheduleExactAlarm;
    case 'nearbyWifiDevices':
      return Permission.nearbyWifiDevices;
    case 'videos':
      return Permission.videos;
    case 'audio':
      return Permission.audio;
    case 'accessMediaLocation':
      return Permission.accessMediaLocation;
    case 'accessNotificationPolicy':
      return Permission.accessNotificationPolicy;
    case 'assistant':
      return Permission.assistant;
    case 'backgroundRefresh':
      return Permission.backgroundRefresh;
    default:
      return null;
  }
}

/// WebF Native Module for permission_handler
///
/// Exposes permission check/request and app settings to JavaScript.
///
/// Usage in JavaScript:
/// ```javascript
/// // Check status (no UI)
/// const status = await webf.invokeModule('PermissionHandler', 'checkStatus', ['camera']);
/// // Returns: 'granted' | 'denied' | 'permanentlyDenied' | 'restricted' | 'limited' | 'provisional'
///
/// // Request permission (may show system dialog)
/// const status = await webf.invokeModule('PermissionHandler', 'request', ['camera']);
///
/// // Request multiple permissions
/// const result = await webf.invokeModule('PermissionHandler', 'requestMultiple', [['camera', 'microphone']]);
/// // Returns: { camera: 'granted', microphone: 'denied' }
///
/// // Open app settings
/// const opened = await webf.invokeModule('PermissionHandler', 'openAppSettings');
/// ```
class PermissionHandlerWebfModule extends WebFBaseModule {
  PermissionHandlerWebfModule(super.manager);

  @override
  String get name => 'PermissionHandler';

  @override
  Future<dynamic> invoke(String method, List<dynamic> arguments) async {
    switch (method) {
      case 'checkStatus':
        return _checkStatus(arguments);
      case 'request':
        return _request(arguments);
      case 'requestMultiple':
        return _requestMultiple(arguments);
      case 'openAppSettings':
        return _openAppSettings();
      case 'shouldShowRequestRationale':
        return _shouldShowRequestRationale(arguments);
      default:
        appLogger.w('[PermissionHandlerWebfModule] Unknown method: $method');
        return returnErr('Unknown method: $method', code: -32601);
    }
  }

  /// Check current status without requesting.
  /// Arguments: [permissionName] e.g. 'camera', 'bluetoothScan'
  /// Returns: status string or error map.
  Future<dynamic> _checkStatus(List<dynamic> arguments) async {
    if (arguments.isEmpty) {
      return returnErr('checkStatus requires permission name', code: -32602);
    }
    final name = arguments[0] as String?;
    if (name == null || name.isEmpty) {
      return returnErr('checkStatus requires permission name', code: -32602);
    }
    final permission = _permissionFromName(name);
    if (permission == null) {
      return returnErr('Unknown permission: $name', code: -32602);
    }
    try {
      final status = await permission.status;
      return returnOk(status.name);
    } catch (e) {
      appLogger.e('[PermissionHandlerWebfModule] checkStatus failed', error: e);
      return returnErr(e.toString(), code: -32602);
    }
  }

  /// Request permission (may show system dialog).
  /// Arguments: [permissionName]
  /// Returns: status string or error map.
  Future<dynamic> _request(List<dynamic> arguments) async {
    if (arguments.isEmpty) {
      return returnErr('request requires permission name', code: -32602);
    }
    final name = arguments[0] as String?;
    if (name == null || name.isEmpty) {
      return returnErr('request requires permission name', code: -32602);
    }
    final permission = _permissionFromName(name);
    if (permission == null) {
      return returnErr('Unknown permission: $name', code: -32602);
    }
    try {
      final status = await permission.request();
      return returnOk(status.name);
    } catch (e) {
      appLogger.e('[PermissionHandlerWebfModule] request failed', error: e);
      return returnErr(e.toString(), code: -32602);
    }
  }

  /// Request multiple permissions at once.
  /// Arguments: [permissionNames] e.g. ['camera', 'microphone']
  /// Returns: `Map<permissionName, status string>` or error map.
  Future<dynamic> _requestMultiple(List<dynamic> arguments) async {
    if (arguments.isEmpty) {
      return returnErr(
        'requestMultiple requires list of permission names',
        code: -32602,
      );
    }
    final list = arguments[0];
    if (list is! List) {
      return returnErr(
        'requestMultiple requires list of permission names',
        code: -32602,
      );
    }
    final names = list.cast<String>();
    final result = <String, String>{};
    for (final name in names) {
      final permission = _permissionFromName(name);
      if (permission == null) {
        result[name] = 'denied'; // treat unknown as denied
        continue;
      }
      try {
        final status = await permission.request();
        result[name] = status.name;
      } catch (e) {
        result[name] = 'denied';
      }
    }
    return returnOk(result);
  }

  /// Whether to show rationale before requesting (Android).
  /// Arguments: [permissionName]
  /// Returns: boolean or error map.
  Future<dynamic> _shouldShowRequestRationale(List<dynamic> arguments) async {
    if (arguments.isEmpty) {
      return returnErr(
        'shouldShowRequestRationale requires permission name',
        code: -32602,
      );
    }
    final name = arguments[0] as String?;
    if (name == null || name.isEmpty) {
      return returnErr(
        'shouldShowRequestRationale requires permission name',
        code: -32602,
      );
    }
    final permission = _permissionFromName(name);
    if (permission == null) {
      return returnErr('Unknown permission: $name', code: -32602);
    }
    try {
      final value = await permission.shouldShowRequestRationale;
      return returnOk(value);
    } catch (e) {
      appLogger.e(
        '[PermissionHandlerWebfModule] shouldShowRequestRationale failed',
        error: e,
      );
      return returnErr(e.toString(), code: -32602);
    }
  }

  /// Open the app's settings page.
  /// Returns: returnOk(true) if settings could be opened.
  Future<dynamic> _openAppSettings() async {
    try {
      final opened = await openAppSettings();
      return returnOk(opened);
    } catch (e) {
      appLogger.e(
        '[PermissionHandlerWebfModule] openAppSettings failed',
        error: e,
      );
      return returnErr(e.toString(), code: -32602);
    }
  }

  @override
  void dispose() {
    // No resources to release
  }
}

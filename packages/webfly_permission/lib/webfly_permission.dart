// Defines PermissionHandlerWebfModule (WebF native module for permission_handler).
// In app: import 'package:webfly_permission/webfly_permission.dart' show PermissionHandlerWebfModule;
//         WebF.defineModule((context) => PermissionHandlerWebfModule(context));

import 'package:flutter/foundation.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:webf/webf.dart';
import 'package:webf_bridge/webf_bridge.dart';

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
        debugPrint('[webfly_permission] Unknown method: $method');
        return webfErr('Unknown method: $method');
    }
  }

  Future<dynamic> _checkStatus(List<dynamic> arguments) async {
    if (arguments.isEmpty) {
      return webfErr('checkStatus requires permission name');
    }
    final name = arguments[0] as String?;
    if (name == null || name.isEmpty) {
      return webfErr('checkStatus requires permission name');
    }
    final permission = _permissionFromName(name);
    if (permission == null) {
      return webfErr('Unknown permission: $name');
    }
    try {
      final status = await permission.status;
      return webfOk(status.name);
    } catch (e) {
      debugPrint('[webfly_permission] checkStatus failed: $e');
      return webfErr(e.toString());
    }
  }

  Future<dynamic> _request(List<dynamic> arguments) async {
    if (arguments.isEmpty) {
      return webfErr('request requires permission name');
    }
    final name = arguments[0] as String?;
    if (name == null || name.isEmpty) {
      return webfErr('request requires permission name');
    }
    final permission = _permissionFromName(name);
    if (permission == null) {
      return webfErr('Unknown permission: $name');
    }
    try {
      final status = await permission.request();
      return webfOk(status.name);
    } catch (e) {
      debugPrint('[webfly_permission] request failed: $e');
      return webfErr(e.toString());
    }
  }

  Future<dynamic> _requestMultiple(List<dynamic> arguments) async {
    if (arguments.isEmpty) {
      return webfErr('requestMultiple requires list of permission names');
    }
    final list = arguments[0];
    if (list is! List) {
      return webfErr('requestMultiple requires list of permission names');
    }
    final names = list.cast<String>();
    final result = <String, String>{};
    for (final name in names) {
      final permission = _permissionFromName(name);
      if (permission == null) {
        result[name] = 'denied';
        continue;
      }
      try {
        final status = await permission.request();
        result[name] = status.name;
      } catch (e) {
        result[name] = 'denied';
      }
    }
    return webfOk(result);
  }

  Future<dynamic> _shouldShowRequestRationale(List<dynamic> arguments) async {
    if (arguments.isEmpty) {
      return webfErr('shouldShowRequestRationale requires permission name');
    }
    final name = arguments[0] as String?;
    if (name == null || name.isEmpty) {
      return webfErr('shouldShowRequestRationale requires permission name');
    }
    final permission = _permissionFromName(name);
    if (permission == null) {
      return webfErr('Unknown permission: $name');
    }
    try {
      final value = await permission.shouldShowRequestRationale;
      return webfOk(value);
    } catch (e) {
      debugPrint('[webfly_permission] shouldShowRequestRationale failed: $e');
      return webfErr(e.toString());
    }
  }

  Future<dynamic> _openAppSettings() async {
    try {
      final opened = await openAppSettings();
      return webfOk(opened);
    } catch (e) {
      debugPrint('[webfly_permission] openAppSettings failed: $e');
      return webfErr(e.toString());
    }
  }

  @override
  void dispose() {}
}

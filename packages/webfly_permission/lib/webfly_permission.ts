/** PermissionHandler WebF module (TS). Usage: import { checkStatus, request, ... } from '@webfly/permission' */

import { createModuleInvoker, type Result } from '../../webf_bridge/lib/webf_bridge';

const invoke = createModuleInvoker('PermissionHandler');

export type PermissionStatus =
  | 'granted'
  | 'denied'
  | 'permanentlyDenied'
  | 'restricted'
  | 'limited'
  | 'provisional';

export type PermissionName =
  | 'camera'
  | 'microphone'
  | 'bluetooth'
  | 'bluetoothScan'
  | 'bluetoothConnect'
  | 'bluetoothAdvertise'
  | 'location'
  | 'locationWhenInUse'
  | 'locationAlways'
  | 'notification'
  | 'photos'
  | 'photosAddOnly'
  | 'storage'
  | 'manageExternalStorage'
  | 'contacts'
  | 'calendarFullAccess'
  | 'calendarWriteOnly'
  | 'sms'
  | 'phone'
  | 'mediaLibrary'
  | 'speech'
  | 'sensors'
  | 'sensorsAlways'
  | 'ignoreBatteryOptimizations'
  | 'activityRecognition'
  | 'reminders'
  | 'criticalAlerts'
  | 'appTrackingTransparency'
  | 'systemAlertWindow'
  | 'requestInstallPackages'
  | 'scheduleExactAlarm'
  | 'nearbyWifiDevices'
  | 'videos'
  | 'audio'
  | 'accessMediaLocation'
  | 'accessNotificationPolicy'
  | 'assistant'
  | 'backgroundRefresh';

export function checkStatus(
  permission: PermissionName | string
): Promise<Result<PermissionStatus, string>> {
  return invoke<PermissionStatus>('checkStatus', permission);
}

export function request(
  permission: PermissionName | string
): Promise<Result<PermissionStatus, string>> {
  return invoke<PermissionStatus>('request', permission);
}

export function requestMultiple(
  permissions: (PermissionName | string)[]
): Promise<Result<Record<string, PermissionStatus>, string>> {
  return invoke<Record<string, PermissionStatus>>('requestMultiple', permissions);
}

export function openAppSettings(): Promise<Result<boolean, string>> {
  return invoke<boolean>('openAppSettings');
}

export function shouldShowRequestRationale(
  permission: PermissionName | string
): Promise<Result<boolean, string>> {
  return invoke<boolean>('shouldShowRequestRationale', permission);
}

/**
 * PermissionHandler WebF module: check/request permissions and app settings.
 * Matches webf/permission.dart.
 *
 * Usage:
 *   import { checkStatus, request, openAppSettings, isWebfError } from '@native/webf/permission';
 *   const status = await checkStatus('camera');
 */

import { createModuleInvoker, isWebfError, type WebfResponse } from './bridge';

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

/** Re-export for callers that want a single import. */
export { isWebfError };

/**
 * Check current permission status (no UI).
 * @returns WebfResponse<PermissionStatus>
 */
export function checkStatus(
  permission: PermissionName | string
): Promise<WebfResponse<PermissionStatus>> {
  return invoke<WebfResponse<PermissionStatus>>('checkStatus', permission);
}

/**
 * Request permission (may show system dialog).
 * @returns WebfResponse<PermissionStatus>
 */
export function request(
  permission: PermissionName | string
): Promise<WebfResponse<PermissionStatus>> {
  return invoke<WebfResponse<PermissionStatus>>('request', permission);
}

/**
 * Request multiple permissions at once.
 * @returns WebfResponse<Record<string, PermissionStatus>>
 */
export function requestMultiple(
  permissions: (PermissionName | string)[]
): Promise<WebfResponse<Record<string, PermissionStatus>>> {
  return invoke<WebfResponse<Record<string, PermissionStatus>>>('requestMultiple', permissions);
}

/**
 * Open the app's settings page.
 * @returns WebfResponse<boolean>
 */
export function openAppSettings(): Promise<WebfResponse<boolean>> {
  return invoke<WebfResponse<boolean>>('openAppSettings');
}

/**
 * Whether to show a rationale before requesting (Android).
 * @returns WebfResponse<boolean>
 */
export function shouldShowRequestRationale(
  permission: PermissionName | string
): Promise<WebfResponse<boolean>> {
  return invoke<WebfResponse<boolean>>('shouldShowRequestRationale', permission);
}

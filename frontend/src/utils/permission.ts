/**
 * WebF PermissionHandler module bridge.
 * Re-exports from @native/webf/permission with throw-on-error wrappers for compatibility.
 *
 * @see https://github.com/openwebf/webf/blob/main/skills/webf-native-plugin-dev/SKILL.md
 */

import {
  checkStatus as checkStatusNative,
  isWebfError,
  openAppSettings as openAppSettingsNative,
  request as requestNative,
  requestMultiple as requestMultipleNative,
  shouldShowRequestRationale as shouldShowRequestRationaleNative,
  type PermissionName,
  type PermissionStatus,
} from '@native/webf/permission'
import { isWebfAvailable } from '@native/webf/bridge'

export type { PermissionName, PermissionStatus }

/**
 * Check current permission status (no UI).
 * @throws if module returns error
 */
export async function checkStatus(
  permission: PermissionName | string
): Promise<PermissionStatus> {
  const res = await checkStatusNative(permission)
  if (isWebfError(res)) {
    throw new Error(res.error?.message ?? 'Permission check failed')
  }
  return res.result as PermissionStatus
}

/**
 * Request permission (may show system dialog).
 * @throws if module returns error
 */
export async function request(
  permission: PermissionName | string
): Promise<PermissionStatus> {
  const res = await requestNative(permission)
  if (isWebfError(res)) {
    throw new Error(res.error?.message ?? 'Permission request failed')
  }
  return res.result as PermissionStatus
}

/**
 * Request multiple permissions at once.
 * @throws if module returns error
 */
export async function requestMultiple(
  permissions: (PermissionName | string)[]
): Promise<Record<string, PermissionStatus>> {
  const res = await requestMultipleNative(permissions)
  if (isWebfError(res)) {
    throw new Error(res.error?.message ?? 'Permission request failed')
  }
  return (res.result ?? {}) as Record<string, PermissionStatus>
}

/**
 * Open the app's settings page.
 */
export async function openAppSettings(): Promise<boolean> {
  const res = await openAppSettingsNative()
  if (isWebfError(res)) return false
  return res.result === true
}

/**
 * Whether to show a rationale before requesting (Android).
 */
export async function shouldShowRequestRationale(
  permission: PermissionName | string
): Promise<boolean> {
  const res = await shouldShowRequestRationaleNative(permission)
  if (isWebfError(res)) return false
  return res.result === true
}

/**
 * Check if PermissionHandler module is available (e.g. running inside WebF).
 */
export function isPermissionHandlerAvailable(): boolean {
  return isWebfAvailable()
}

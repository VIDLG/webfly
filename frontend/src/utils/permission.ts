/**
 * WebF PermissionHandler module bridge.
 * Re-exports from @webfly/permission with throw-on-error wrappers for compatibility.
 *
 * @see https://github.com/openwebf/webf/blob/main/skills/webf-native-plugin-dev/SKILL.md
 */

import {
  checkStatus as checkStatusNative,
  openAppSettings as openAppSettingsNative,
  request as requestNative,
  requestMultiple as requestMultipleNative,
  shouldShowRequestRationale as shouldShowRequestRationaleNative,
  type PermissionName,
  type PermissionStatus,
} from '@webfly/permission'
import { isWebfAvailable } from '../../../lib/webf/bridge.ts'

export type { PermissionName, PermissionStatus }

/**
 * Check current permission status (no UI).
 * @throws if module returns error
 */
export async function checkStatus(
  permission: PermissionName | string
): Promise<PermissionStatus> {
  const res = await checkStatusNative(permission)
  if (res.isErr()) throw new Error(res.error ?? 'Permission check failed')
  return res.value as PermissionStatus
}

/**
 * Request permission (may show system dialog).
 * @throws if module returns error
 */
export async function request(
  permission: PermissionName | string
): Promise<PermissionStatus> {
  const res = await requestNative(permission)
  if (res.isErr()) throw new Error(res.error ?? 'Permission request failed')
  return res.value as PermissionStatus
}

/**
 * Request multiple permissions at once.
 * @throws if module returns error
 */
export async function requestMultiple(
  permissions: (PermissionName | string)[]
): Promise<Record<string, PermissionStatus>> {
  const res = await requestMultipleNative(permissions)
  if (res.isErr()) throw new Error(res.error ?? 'Permission request failed')
  return (res.value ?? {}) as Record<string, PermissionStatus>
}

/**
 * Open the app's settings page.
 */
export async function openAppSettings(): Promise<boolean> {
  const res = await openAppSettingsNative()
  if (res.isErr()) return false
  return res.value === true
}

/**
 * Whether to show a rationale before requesting (Android).
 */
export async function shouldShowRequestRationale(
  permission: PermissionName | string
): Promise<boolean> {
  const res = await shouldShowRequestRationaleNative(permission)
  if (res.isErr()) return false
  return res.value === true
}

/**
 * Check if PermissionHandler module is available (e.g. running inside WebF).
 */
export function isPermissionHandlerAvailable(): boolean {
  return isWebfAvailable()
}

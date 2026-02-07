/**
 * AppSettings WebF module: theme and app preferences.
 * Matches webf/app_settings.dart.
 *
 * Usage:
 *   import { getTheme, setTheme, getSystemTheme } from '@native/webf/app_settings';
 *   const theme = await getTheme();  // 'light' | 'dark' | 'system'
 *   await setTheme('dark');
 *
 * Theme changes: WebF dispatches 'colorschemchange' (see OpenWebF theming docs).
 * Listen via window.addEventListener('colorschemchange', ...) and optionally getTheme() to sync preference.
 */

import { createModuleInvoker, type WebfResponse } from './bridge';

const invoke = createModuleInvoker('AppSettings');

export type ThemePreference = 'light' | 'dark' | 'system';

/**
 * Get current theme preference.
 * @returns WebfResponse<ThemePreference>
 */
export function getTheme(): Promise<WebfResponse<ThemePreference>> {
  return invoke<WebfResponse<ThemePreference>>('getTheme');
}

/**
 * Set theme preference.
 * @param theme - 'light' | 'dark' | 'system'
 * @returns WebfResponse<boolean>
 */
export function setTheme(theme: ThemePreference): Promise<WebfResponse<boolean>> {
  return invoke<WebfResponse<boolean>>('setTheme', theme);
}

/**
 * Get current platform (system) theme.
 * @returns WebfResponse<'light' | 'dark'>
 */
export function getSystemTheme(): Promise<WebfResponse<'light' | 'dark'>> {
  return invoke<WebfResponse<'light' | 'dark'>>('getSystemTheme');
}

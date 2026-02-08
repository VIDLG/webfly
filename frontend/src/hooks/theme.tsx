/* eslint-disable react-refresh/only-export-components */
import React, { createContext, useContext, useEffect, useState, useCallback, useRef } from 'react'
import { getTheme as getAppTheme, setTheme as setAppTheme } from '../../../lib/webf/app_settings.ts'
import { isWebfAvailable, isWebfError } from '../../../lib/webf/bridge.ts'

export type ThemePreference = 'light' | 'dark' | 'system'
export type ResolvedTheme = 'light' | 'dark'

function normalizeThemePreference(value: unknown): ThemePreference {
  if (value === 'light' || value === 'dark' || value === 'system') return value
  return 'system'
}

export interface ThemeContextType {
  theme: ResolvedTheme // Resolved theme (light or dark)
  themePreference: ThemePreference // User preference (light, dark, or system)
  setThemePreference: (preference: ThemePreference) => Promise<void>
  toggleTheme: () => Promise<void>
}

const ThemeContext = createContext<ThemeContextType | undefined>(undefined)

// 官方要求 media 模式，Tailwind 由 prefers-color-scheme 驱动。仅设 data-theme 便于调试。
function applyThemeHint(theme: ResolvedTheme) {
  document.documentElement.dataset.theme = theme
}

type ColorScheme = 'light' | 'dark' | 'no-preference'

/**
 * React hook for detecting prefers-color-scheme media query
 * Following WebF official recommendation: https://openwebf.com/en/docs/add-webf-to-flutter/advanced-topics/theming
 * 
 * Returns 'dark', 'light', or 'no-preference' (for SSR)
 * 
 * @example
 * ```tsx
 * const prefersColorScheme = usePrefersColorScheme()
 * const isDark = prefersColorScheme === 'dark'
 * ```
 */
function usePrefersColorScheme(): ColorScheme {
  const [colorScheme, setColorScheme] = useState<ColorScheme>(() => {
    if (typeof window === 'undefined') return 'no-preference'
    return window.matchMedia('(prefers-color-scheme: dark)').matches ? 'dark' : 'light'
  })

  useEffect(() => {
    if (typeof window === 'undefined') return

    const syncFromMedia = () => {
      setColorScheme(
        window.matchMedia('(prefers-color-scheme: dark)').matches ? 'dark' : 'light'
      )
    }

    const mediaQuery = window.matchMedia('(prefers-color-scheme: dark)')
    const handleChange = (e: MediaQueryListEvent) => {
      setColorScheme(e.matches ? 'dark' : 'light')
    }

    let legacyHandler: ((mql: MediaQueryList | MediaQueryListEvent) => void) | null = null
    if (mediaQuery.addEventListener) {
      mediaQuery.addEventListener('change', handleChange)
    } else if (mediaQuery.addListener) {
      legacyHandler = (mql: MediaQueryList | MediaQueryListEvent) => {
        setColorScheme(mql.matches ? 'dark' : 'light')
      }
      mediaQuery.addListener(legacyHandler)
    }

    // WebF: when Flutter sets darkModeOverride, WebF updates media query and
    // dispatches 'colorschemchange'. Listen on both window and document (WebF may use either).
    const onColorSchemeChange = () => syncFromMedia()
    window.addEventListener('colorschemchange', onColorSchemeChange)
    document.addEventListener('colorschemchange', onColorSchemeChange)

    return () => {
      if (mediaQuery.removeEventListener) {
        mediaQuery.removeEventListener('change', handleChange)
      } else if (mediaQuery.removeListener && legacyHandler) {
        mediaQuery.removeListener(legacyHandler)
      }
      window.removeEventListener('colorschemchange', onColorSchemeChange)
      document.removeEventListener('colorschemchange', onColorSchemeChange)
    }
  }, [])

  return colorScheme
}

export function ThemeProvider({ children }: { children: React.ReactNode }): React.JSX.Element {
  const [themePreference, setThemePreferenceState] = useState<ThemePreference>('system')
  const initializedRef = useRef(false)

  // Initialize theme preference from Flutter AppSettings on mount.
  // Important: in WebF the `window.webf` bridge may not be ready on first paint.
  useEffect(() => {
    if (typeof window === 'undefined' || initializedRef.current) return

    let cancelled = false

    const loadThemeFromFlutter = async () => {
      let lastError: unknown

      // Wait up to ~2s for WebF bridge and module invocation to be available.
      for (let attempt = 0; attempt < 40 && !cancelled; attempt += 1) {
        if (!isWebfAvailable()) {
          await new Promise<void>((resolve) => setTimeout(resolve, 50))
          continue
        }

        try {
          const res = await getAppTheme()
          if (isWebfError(res)) {
            lastError = res
            await new Promise<void>((resolve) => setTimeout(resolve, 50))
            continue
          }
          if (res.result != null) {
            const normalized = normalizeThemePreference(res.result)
            setThemePreferenceState(normalized)
            initializedRef.current = true
            return
          }
        } catch (e) {
          lastError = e
          await new Promise<void>((resolve) => setTimeout(resolve, 50))
        }
      }

      if (!cancelled) {
        console.warn('[ThemeContext] Failed to load theme from Flutter (bridge not ready?):', lastError)
        initializedRef.current = true
      }
    }

    void loadThemeFromFlutter()
    return () => {
      cancelled = true
    }
  }, [])

  // 使用系统事件 colorschemchange（WebF 文档）：收到后从 Flutter 拉取 theme 偏好以保持同步。
  // 同时在 window 和 document 上监听；visibilitychange 时再同步一次。
  // 兜底：若事件未派发（如 evaluateJavaScripts 未执行），用短间隔轮询在可见时与 Flutter 同步。
  useEffect(() => {
    if (typeof window === 'undefined') return

    const syncPreferenceFromFlutter = () => {
      getAppTheme().then((res) => {
        if (res.result != null) {
          setThemePreferenceState(normalizeThemePreference(res.result))
        }
      }).catch(() => {})
    }

    const onColorSchemeChange = () => syncPreferenceFromFlutter()
    window.addEventListener('colorschemchange', onColorSchemeChange)
    document.addEventListener('colorschemchange', onColorSchemeChange)

    const onVisibilityChange = () => {
      if (document.visibilityState === 'visible') syncPreferenceFromFlutter()
    }
    document.addEventListener('visibilitychange', onVisibilityChange)

    // Fallback: poll Flutter theme every 2s while visible so theme syncs even if event never fires
    const pollInterval = 2000
    const pollId = setInterval(() => {
      if (document.visibilityState === 'visible') syncPreferenceFromFlutter()
    }, pollInterval)

    return () => {
      window.removeEventListener('colorschemchange', onColorSchemeChange)
      document.removeEventListener('colorschemchange', onColorSchemeChange)
      document.removeEventListener('visibilitychange', onVisibilityChange)
      clearInterval(pollId)
    }
  }, [])

  // system 时用 prefers-color-scheme；light/dark 时用用户偏好。
  // WebF 文档：设置 darkModeOverride 后会更新 media 并派发 colorschemchange，Tailwind dark: 自动生效。
  const prefersColorScheme = usePrefersColorScheme()
  const resolvedTheme: ResolvedTheme =
    themePreference === 'system'
      ? (prefersColorScheme === 'dark' ? 'dark' : 'light')
      : themePreference

  useEffect(() => {
    applyThemeHint(resolvedTheme)
  }, [resolvedTheme])

  // 同步到 Flutter；Flutter 设置 darkModeOverride 后 WebF 更新 media + colorschemchange，无需 reload
  const setThemePreference = useCallback(async (preference: ThemePreference): Promise<void> => {
    const normalized = normalizeThemePreference(preference)
    setThemePreferenceState(normalized)
    try {
      const res = await setAppTheme(normalized)
      if (isWebfError(res) || res.result !== true) {
        const themeRes = await getAppTheme()
        if (themeRes.result != null) setThemePreferenceState(normalizeThemePreference(themeRes.result))
      }
    } catch (e) {
      console.warn('[ThemeContext] Failed to sync theme to Flutter:', e)
      const themeRes = await getAppTheme()
      if (themeRes.result != null) setThemePreferenceState(normalizeThemePreference(themeRes.result))
    }
  }, [])

  const toggleTheme = useCallback(async () => {
    const nextPreference: ThemePreference = 
      themePreference === 'system' ? 'dark' :
      themePreference === 'dark' ? 'light' : 'dark'
    await setThemePreference(nextPreference)
  }, [themePreference, setThemePreference])

  return (
    <ThemeContext.Provider value={{ 
      theme: resolvedTheme, 
      themePreference, 
      setThemePreference, 
      toggleTheme 
    }}>
      {children}
    </ThemeContext.Provider>
  )
}

/** Fallback when context is missing (e.g. during Vite HMR when theme.tsx is replaced and Provider identity changes). */
const defaultThemeContext: ThemeContextType = {
  theme: 'light',
  themePreference: 'system',
  setThemePreference: async () => {},
  toggleTheme: async () => {},
}

export function useTheme(): ThemeContextType {
  const context = useContext(ThemeContext)
  if (context === undefined) {
    return defaultThemeContext
  }
  return context
}

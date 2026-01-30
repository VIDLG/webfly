/* eslint-disable react-refresh/only-export-components */
import React, { createContext, useContext, useEffect, useState, useCallback, useRef } from 'react'
import { invokeWebFModule } from '../utils/webf'

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

// With Tailwind `darkMode: 'media'`, the actual styling is controlled by
// `prefers-color-scheme` (in WebF, Flutter can override it via darkModeOverride).
// We keep only a data attribute for debugging.
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

    const mediaQuery = window.matchMedia('(prefers-color-scheme: dark)')
    
    const handleChange = (e: MediaQueryListEvent) => {
      setColorScheme(e.matches ? 'dark' : 'light')
    }

    // Use modern addEventListener API if available
    if (mediaQuery.addEventListener) {
      mediaQuery.addEventListener('change', handleChange)
      return () => {
        mediaQuery.removeEventListener('change', handleChange)
      }
    } 
    // Fallback to legacy addListener API 
    // (WebF might implement this or older browsers)
    else if (mediaQuery.addListener) {
      // safe cast or wrapper to handle potential type mismatch if strict
      const legacyHandler = (mql: MediaQueryList | MediaQueryListEvent) => {
         setColorScheme(mql.matches ? 'dark' : 'light')
      }
      mediaQuery.addListener(legacyHandler)
      return () => {
        mediaQuery.removeListener(legacyHandler)
      }
    } else {
      console.warn('MediaQueryList.addEventListener and addListener are not supported')
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
        const webf = (window as Window & { webf?: unknown }).webf as unknown as {
          invokeModule?: unknown
          invokeModuleAsync?: unknown
        } | undefined

        const bridgeReady = Boolean(webf?.invokeModuleAsync || webf?.invokeModule)
        if (!bridgeReady) {
          await new Promise<void>((resolve) => setTimeout(resolve, 50))
          continue
        }

        try {
          const theme = await invokeWebFModule('AppSettings', 'getTheme')
          const normalized = normalizeThemePreference(theme)
          setThemePreferenceState(normalized)
          initializedRef.current = true
          return
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

  // Use prefers-color-scheme hook to detect system theme
  const prefersColorScheme = usePrefersColorScheme()

  // With darkMode=media, CSS follows prefers-color-scheme.
  const resolvedTheme: ResolvedTheme = prefersColorScheme === 'dark' ? 'dark' : 'light'

  // Apply resolved theme
  useEffect(() => {
    applyThemeHint(resolvedTheme)
  }, [resolvedTheme])

  // Sync theme preference to Flutter AppSettings when it changes
  const setThemePreference = useCallback(async (preference: ThemePreference) => {
    const normalized = normalizeThemePreference(preference)
    setThemePreferenceState(normalized)
    
    // Notify Flutter about theme change using WebF Native Module
    // Native Module is the recommended way for JavaScript → Flutter communication
    try {
      const ok = await invokeWebFModule('AppSettings', 'setTheme', normalized)
      if (ok !== true) {
        // Dart side is the source of truth. If it rejects, re-sync from Dart.
        const theme = await invokeWebFModule('AppSettings', 'getTheme')
        setThemePreferenceState(normalizeThemePreference(theme))
        return
      }

    } catch (e) {
      console.warn('[ThemeContext] Failed to sync theme to Flutter:', e)
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

export function useTheme() {
  const context = useContext(ThemeContext)
  if (context === undefined) {
    throw new Error('useTheme must be used within a ThemeProvider')
  }
  return context
}

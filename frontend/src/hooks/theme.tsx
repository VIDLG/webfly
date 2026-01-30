/* eslint-disable react-refresh/only-export-components */
import React, { createContext, useContext, useEffect, useState, useCallback } from 'react'
import { invokeWebFModule } from '../utils/webf'
import { themes } from '../config'

export type ThemePreference = 'light' | 'dark' | 'system'
export type ResolvedTheme = 'light' | 'dark'

export interface ThemeContextType {
  theme: ResolvedTheme // Resolved theme (light or dark)
  themePreference: ThemePreference // User preference (light, dark, or system)
  setThemePreference: (preference: ThemePreference) => Promise<void>
  toggleTheme: () => Promise<void>
}

export const ThemeContext = createContext<ThemeContextType | undefined>(undefined)

// Pure function - no need for useCallback, can be outside component
function applyTheme(theme: ResolvedTheme) {
  const root = document.documentElement
  const themeColors = themes[theme]
  
  Object.entries(themeColors).forEach(([key, value]) => {
    root.style.setProperty(key, value)
  })
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

    // Use modern addEventListener API
    // Assert that addEventListener exists (required for modern browsers)
    if (!mediaQuery.addEventListener) {
      throw new Error('MediaQueryList.addEventListener is not supported')
    }
    
    mediaQuery.addEventListener('change', handleChange)
    return () => {
      mediaQuery.removeEventListener('change', handleChange)
    }
  }, [])

  return colorScheme
}

export function ThemeProvider({ children }: { children: React.ReactNode }): React.JSX.Element {
  const [themePreference, setThemePreferenceState] = useState<ThemePreference>('system')
  const [isInitialized, setIsInitialized] = useState(false)

  // Initialize theme preference from Flutter AppSettings on mount
  useEffect(() => {
    if (typeof window === 'undefined' || isInitialized) return

    const loadThemeFromFlutter = async () => {
      try {
        const theme = await invokeWebFModule('AppSettings', 'getTheme')
        if (theme && typeof theme === 'string' && ['light', 'dark', 'system'].includes(theme)) {
          setThemePreferenceState(theme as ThemePreference)
        }
      } catch (e) {
        // If webf.invokeModule not available or fails, keep default 'system'
        console.warn('[ThemeContext] Failed to load theme from Flutter:', e)
      } finally {
        setIsInitialized(true)
      }
    }

    loadThemeFromFlutter()
  }, [isInitialized])

  // Use prefers-color-scheme hook to detect system theme
  // WebF automatically syncs prefers-color-scheme with Flutter's theme via darkModeOverride
  // When Flutter sets darkModeOverride=false (light) or true (dark), WebF updates prefers-color-scheme
  // When Flutter sets darkModeOverride=null (system), WebF syncs with system theme
  // Following WebF official recommendation: https://openwebf.com/en/docs/add-webf-to-flutter/advanced-topics/theming
  const prefersColorScheme = usePrefersColorScheme()
  const resolvedTheme: ResolvedTheme = prefersColorScheme === 'dark' ? 'dark' : 'light'

  // Apply resolved theme
  useEffect(() => {
    applyTheme(resolvedTheme)
  }, [resolvedTheme])

  // Sync theme preference to Flutter AppSettings when it changes
  const setThemePreference = useCallback(async (preference: ThemePreference) => {
    setThemePreferenceState(preference)
    
    // Notify Flutter about theme change using WebF Native Module
    // Native Module is the recommended way for JavaScript → Flutter communication
    try {
      await invokeWebFModule('AppSettings', 'setTheme', [preference])
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

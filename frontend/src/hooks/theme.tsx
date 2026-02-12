/* eslint-disable react-refresh/only-export-components */
import React, { createContext, useContext, useEffect, useState, useCallback, useRef } from 'react'
import {
  getTheme as getAppTheme,
  setTheme as setAppTheme,
  addThemeChangeListener,
  type ThemeState,
  type ThemeMode,
  type ResolvedTheme,
} from '@webfly/theme'

export interface ThemeContextType {
  theme: ResolvedTheme // Resolved theme (light or dark)
  themePreference: ThemeMode // User preference (light, dark, or system)
  setThemePreference: (preference: ThemeMode) => Promise<void>
  toggleTheme: () => Promise<void>
}

const ThemeContext = createContext<ThemeContextType | undefined>(undefined)

export function ThemeProvider({ children }: { children: React.ReactNode }): React.JSX.Element {
  const [themeState, setThemeState] = useState<ThemeState>({
    themePreference: 'system',
    resolvedTheme: 'light',
  })
  const initializedRef = useRef(false)

  // Initialize theme preference from Flutter AppSettings on mount.
  // If initialization fails, subsequent themechange events will sync state; this is best-effort only.
  useEffect(() => {
    if (typeof window === 'undefined' || initializedRef.current) return

    let cancelled = false

    const loadThemeFromFlutter = async () => {
      const res = await getAppTheme()
      if (!cancelled && res.isOk()) {
        setThemeState(res.value)
      }
      if (!cancelled) {
        initializedRef.current = true
      }
    }

    void loadThemeFromFlutter()
    return () => {
      cancelled = true
    }
  }, [])

  // Listen to theme changes via ThemeWebfModule ('themechange').
  // ThemeWebfModule uses themeStream and already tracks all Flutter-side changes (including system).
  // The WebF bridge is available when this provider mounts, so we can subscribe directly.
  useEffect(() => {
    const unsubscribe = addThemeChangeListener((state) => {
      setThemeState(state)
    })
    return () => {
      unsubscribe()
    }
  }, [])

  // Sync to Flutter; Flutter sets darkModeOverride and WebF updates media + colorschemchange (no reload).
  const setThemePreference = useCallback(async (preference: ThemeMode): Promise<void> => {
    const res = await setAppTheme(preference)
    if (res.isErr()) {
      throw new Error(res.error)
    }
  }, [])

  const toggleTheme = useCallback(async () => {
    // Determine next preference based on currently rendered resolvedTheme:
    // dark -> light, light -> dark. Ignore "system" and always switch to an explicit light/dark mode.
    const nextPreference: ThemeMode =
      themeState.resolvedTheme === 'dark' ? 'light' : 'dark'
    await setThemePreference(nextPreference)
  }, [themeState.resolvedTheme, setThemePreference])

  return (
    <ThemeContext.Provider value={{ 
      theme: themeState.resolvedTheme,
      themePreference: themeState.themePreference,
      setThemePreference, 
      toggleTheme 
    }}>
      {children}
    </ThemeContext.Provider>
  )
}

export function useTheme(): ThemeContextType {
  const context = useContext(ThemeContext)
  if (context === undefined) {
    throw new Error('useTheme must be used within a ThemeProvider')
  }
  return context
}

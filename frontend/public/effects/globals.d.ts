import type * as ReactNamespace from 'react'

declare global {
  // ── Color types ──────────────────────────────────────────────

  type TaggedColor =
    | { mode: 'rgb'; r: number; g: number; b: number }
    | { mode: 'hsv'; h: number; s: number; v: number }

  // ── Effect machine ───────────────────────────────────────────

  interface EffectMachine {
    status: 'idle' | 'running' | 'paused'
    speed: number
    ledCount: number
    leds: Uint8Array
    tick(): void
    start(): void
    pause(): void
    resume(): void
    stop(): void
    setSpeed(ms: number): void
    setConfig(key: string, value: unknown): void
  }

  interface EffectBaseConfig {
    ledCount?: number
    speed?: number
  }

  // ── Injected globals (host runtime) ──────────────────────────

  const React: typeof ReactNamespace
  const CupertinoComponents: {
    FlutterCupertinoButton: ReactNamespace.ComponentType<any>
    FlutterCupertinoSlider: ReactNamespace.ComponentType<any>
    [key: string]: ReactNamespace.ComponentType<any>
  }

  // ── Theme (injected from host app) ─────────────────────────

  type ResolvedTheme = 'light' | 'dark'
  type ThemeMode = 'light' | 'dark' | 'system'

  interface ThemeContextType {
    theme: ResolvedTheme
    themePreference: ThemeMode
    setThemePreference: (preference: ThemeMode) => Promise<void>
    toggleTheme: () => Promise<void>
  }

  function useTheme(): ThemeContextType

  // ── Device configuration ────────────────────────────────────

  interface DeviceLed {
    index: number
    x: number
    y: number
    guard?: string
  }

  interface DeviceStrip {
    id: string
    name: string
    ledCount: number
    path?: string
    leds: DeviceLed[]
  }

  interface DeviceRotorGuard {
    cx: number
    cy: number
    radius: number
  }

  interface DeviceConfig {
    id: string
    name: string
    description: string
    coordinateUnit: string
    canvas: { width: number; height: number; origin: string }
    rotorGuards?: Record<string, DeviceRotorGuard>
    strips: DeviceStrip[]
  }

  type OnTickCallback = (leds: Uint8Array) => void

  // ── effect-runtime.js ────────────────────────────────────────

  function hsvToRgb(h: number, s: number, v: number): [number, number, number]
  function toRgb(c: TaggedColor): [number, number, number]
  function makeBlank(ledCount: number): Uint8Array
  function createBaseMachine(
    ledCount: number,
    speed: number,
    handlers: {
      tick(machine: EffectMachine): void
      reset?(): void
      setConfig?(key: string, value: unknown): void
    },
  ): EffectMachine

  // ── {effect}/effect.js ───────────────────────────────────────

  function createEffect(config?: EffectBaseConfig): EffectMachine
}

export {}

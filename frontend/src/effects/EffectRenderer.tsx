/**
 * EffectRenderer — renders LED effect UIs using json-render.
 *
 * Provides a unified layout:
 *   - **Common controls** (LED preview, speed slider, play/pause/stop buttons)
 *     are rendered directly by this component.
 *   - **Effect-specific parameters** (color, waveWidth, chaseCount, etc.)
 *     are rendered dynamically via json-render from the effect's ui.json spec.
 */

import { useCallback, useEffect, useMemo, useRef, useState } from 'react'
import * as ReactNamespace from 'react'
import { FlutterCupertinoSlider } from '@openwebf/react-cupertino-ui'
import { useTheme } from '../hooks/theme'
import { effectRegistry } from './registry'
import {
  EffectMachineContext,
  type EffectMachineContextValue,
} from './EffectMachineContext'
import { createUseEffectMachine, type CreateEffectFn } from './useEffectMachineCore'
import DynamicRenderer, { getBabelApi } from '../components/DynamicRenderer'
import type { DeviceConfig } from '../types/device'
import type { Spec } from '@json-render/core'

// ── Bridge config ────────────────────────────────────────────

export interface EffectBridgeConfig {
  colorKeys?: string[]
  scaleKeys?: Record<string, number>
}

// ── Speed config (declared in ui.json) ───────────────────────

export interface SpeedConfig {
  min: number
  max: number
  default: number
}

// ── Compile effect logic → createEffect ──────────────────────

function useCompiledCreateEffect(effectLogicCode: string): CreateEffectFn | null {
  const [createEffect, setCreateEffect] = useState<CreateEffectFn | null>(null)
  const [error, setError] = useState<string | null>(null)

  useEffect(() => {
    let cancelled = false
    try {
      const babelApi = getBabelApi()
      const result = babelApi.transform(effectLogicCode, {
        filename: 'effect-logic.ts',
        presets: ['typescript'],
        plugins: ['transform-modules-commonjs'],
        sourceType: 'module',
      })

      const compiled = result.code
      if (!compiled) throw new Error('Compiled effect logic code is empty')

      // eslint-disable-next-line @typescript-eslint/no-explicit-any
      const exportsObj: any = {}
      // eslint-disable-next-line @typescript-eslint/no-explicit-any
      const moduleObj: any = { exports: exportsObj }

      const fn = new Function(
        'React', 'exports', 'module',
        `${compiled}\nreturn typeof createEffect === 'function' ? createEffect : (module.exports?.createEffect ?? exports.createEffect);`,
      )
      const extracted = fn(ReactNamespace, exportsObj, moduleObj)

      if (typeof extracted !== 'function') {
        throw new Error('Could not extract createEffect function from effect code')
      }

      if (!cancelled) {
        setCreateEffect(() => extracted as CreateEffectFn)
        setError(null)
      }
    } catch (e) {
      console.error('Failed to compile effect logic:', e)
      if (!cancelled) {
        setError(e instanceof Error ? e.message : String(e))
        setCreateEffect(null)
      }
    }
    return () => { cancelled = true }
  }, [effectLogicCode])

  if (error) console.error('Effect logic compilation error:', error)

  return createEffect
}

// ── EffectMachine hook (from shared core) ────────────────────

const useEffectMachine = createUseEffectMachine({
  useRef,
  useState,
  useCallback,
  useEffect,
})

// ── State bridge: json-render state → EffectMachine ──────────

function createStateBridge(
  machineCtx: EffectMachineContextValue,
  stateRef: React.MutableRefObject<Record<string, unknown>>,
  bridgeConfig?: EffectBridgeConfig,
) {
  const colorKeySet = new Set(bridgeConfig?.colorKeys ?? [])
  const hasColorGroup = colorKeySet.size > 0
  const scaleKeys = bridgeConfig?.scaleKeys ?? {}

  return (path: string, value: unknown) => {
    const segments = path.split('/').filter(Boolean)
    if (segments[0] !== 'effect' || segments.length < 2) return

    const key = segments[1]

    const effectState = (stateRef.current.effect ?? {}) as Record<string, unknown>
    effectState[key] = value
    stateRef.current = { ...stateRef.current, effect: effectState }

    if (key === 'speed') {
      machineCtx.handleSpeedChange(value as number)
    } else if (hasColorGroup && colorKeySet.has(key)) {
      const h = (effectState.hue as number) ?? 0
      const s = (effectState.saturation as number) ?? 100
      const b = (effectState.brightness as number) ?? 100
      machineCtx.machine.setConfig('color', {
        mode: 'hsv',
        h,
        s: s / 100,
        v: b / 100,
      })
    } else {
      const scale = scaleKeys[key]
      const finalValue = scale != null ? (value as number) * scale : value
      machineCtx.machine.setConfig(key, finalValue)
    }
  }
}

// ── Common UI: LED Preview ───────────────────────────────────
// Uses canvas to avoid React re-renders on every tick.
// subscribeTick drives direct canvas draws — no setState needed.

function LEDPreview({ machineCtx }: { machineCtx: EffectMachineContextValue }) {
  const { machine, subscribeTick } = machineCtx
  const canvasRef = useRef<HTMLCanvasElement>(null)

  useEffect(() => {
    const canvas = canvasRef.current
    if (!canvas) return
    const ctx = canvas.getContext('2d')
    if (!ctx) return

    const ledCount = machine.ledCount
    const COLS = Math.min(ledCount, 15)
    const ROWS = Math.ceil(ledCount / COLS)
    const CELL = 44   // px per cell
    const R = 14      // LED radius

    const dpr = window.devicePixelRatio || 1
    const cssW = COLS * CELL
    const cssH = ROWS * CELL
    canvas.width = cssW * dpr
    canvas.height = cssH * dpr
    canvas.style.width = `${cssW}px`
    canvas.style.height = `${cssH}px`
    ctx.scale(dpr, dpr)

    const draw = () => {
      const leds = machine.leds
      ctx.clearRect(0, 0, cssW, cssH)
      for (let i = 0; i < ledCount; i++) {
        const o = i * 3
        const r = leds[o], g = leds[o + 1], b = leds[o + 2]
        const lit = r > 0 || g > 0 || b > 0
        const cx = (i % COLS) * CELL + CELL / 2
        const cy = Math.floor(i / COLS) * CELL + CELL / 2
        if (lit) {
          ctx.beginPath()
          ctx.arc(cx, cy, R * 1.7, 0, Math.PI * 2)
          ctx.fillStyle = `rgba(${r},${g},${b},0.25)`
          ctx.fill()
          ctx.beginPath()
          ctx.arc(cx, cy, R, 0, Math.PI * 2)
          ctx.fillStyle = `rgb(${r},${g},${b})`
          ctx.fill()
        } else {
          ctx.beginPath()
          ctx.arc(cx, cy, R * 0.65, 0, Math.PI * 2)
          ctx.fillStyle = 'rgba(148,163,184,0.3)'
          ctx.fill()
        }
      }
    }

    draw()
    return subscribeTick(draw)
  }, [machine, subscribeTick])

  return (
    <div className="flex items-center justify-center bg-white/70 p-4 dark:bg-slate-900/60 overflow-x-auto">
      <canvas ref={canvasRef} />
    </div>
  )
}

// ── Common UI: Speed Slider ──────────────────────────────────

function SpeedSlider({ machineCtx, speedConfig }: { machineCtx: EffectMachineContextValue; speedConfig: SpeedConfig }) {
  const dark = useTheme().theme === 'dark'
  const accent = dark ? '#60a5fa' : '#3b82f6'

  return (
    <div className="rounded-xl border border-slate-200 bg-white/70 p-4 dark:border-slate-800 dark:bg-slate-900/60">
      <div className="flex justify-between items-center mb-3">
        <label className="text-sm font-bold text-slate-600 dark:text-slate-400">Speed</label>
        <span className="rounded-md border border-slate-300 bg-white px-3 py-1 font-mono text-xs dark:border-slate-700 dark:bg-slate-900/60" style={{ color: accent }}>
          {Math.round(machineCtx.speed)}ms
        </span>
      </div>
      <FlutterCupertinoSlider
        val={machineCtx.speed}
        min={speedConfig.min}
        max={speedConfig.max}
        onChange={(e: CustomEvent<number>) => machineCtx.handleSpeedChange(e.detail)}
        {...{ activeColor: accent }}
      />
      <div className="flex justify-between text-[11px] text-slate-600 dark:text-slate-400 font-medium px-1 mt-2 uppercase tracking-wide">
        <span>Fast</span><span>Slow</span>
      </div>
    </div>
  )
}

// ── Common UI: Play Controls ─────────────────────────────────

function PlayControls({ machineCtx }: { machineCtx: EffectMachineContextValue }) {
  const dark = useTheme().theme === 'dark'
  const { isIdle, isPaused, handleStart, handleStop, handlePauseResume } = machineCtx

  return (
    <div className="flex items-center justify-center gap-3">
      <div className="flex-1">
        <button
          onClick={isIdle ? handleStart : handleStop}
          className="w-full rounded-xl py-3 text-center text-sm font-semibold text-white transition-colors active:opacity-80"
          style={{
            backgroundColor: isIdle ? (dark ? '#34d399' : '#10b981') : dark ? '#f87171' : '#ef4444',
          }}
        >
          {isIdle ? 'Start' : 'Stop'}
        </button>
      </div>
      <div className="flex-1">
        <button
          onClick={handlePauseResume}
          disabled={isIdle}
          className="w-full rounded-xl py-3 text-center text-sm font-semibold text-white transition-colors active:opacity-80"
          style={{
            backgroundColor: isIdle
              ? dark ? '#475569' : '#94a3b8'
              : isPaused
                ? dark ? '#fbbf24' : '#f59e0b'
                : dark ? '#60a5fa' : '#3b82f6',
            opacity: isIdle ? 0.4 : 1,
          }}
        >
          {isPaused ? 'Resume' : 'Pause'}
        </button>
      </div>
    </div>
  )
}

// ── Props ────────────────────────────────────────────────────

export interface EffectRendererProps {
  uiSpec: Spec
  effectLogicCode: string
  deviceConfig: DeviceConfig | null
  onTick?: (leds: Uint8Array) => void
  bridgeConfig?: EffectBridgeConfig
  speedConfig?: SpeedConfig
}

// ── Inner renderer (after createEffect is ready) ─────────────

const DEFAULT_SPEED_CONFIG: SpeedConfig = { min: 20, max: 1000, default: 200 }

function EffectRendererInner({
  createEffect,
  uiSpec,
  deviceConfig,
  onTick,
  bridgeConfig,
  speedConfig,
}: {
  createEffect: CreateEffectFn
  uiSpec: Spec
  deviceConfig: DeviceConfig | null
  onTick?: (leds: Uint8Array) => void
  bridgeConfig?: EffectBridgeConfig
  speedConfig: SpeedConfig
}) {
  const ledCount = deviceConfig ? deviceConfig.strips.reduce((sum, s) => sum + s.ledCount, 0) : 20
  const machineCtx = useEffectMachine(createEffect, { ledCount }, onTick)

  const stateRef = useRef<Record<string, unknown>>(uiSpec.state ?? {})

  const bridge = useMemo(
    () => createStateBridge(machineCtx, stateRef, bridgeConfig),
    // eslint-disable-next-line react-hooks/exhaustive-deps
    [machineCtx.machine, machineCtx.handleSpeedChange, bridgeConfig],
  )

  const handleStateChange = useCallback(
    (path: string, value: unknown) => bridge(path, value),
    [bridge],
  )

  return (
    <EffectMachineContext.Provider value={machineCtx}>
      <div className="flex flex-col h-full font-sans text-slate-900 dark:text-slate-100">
        {/* Common: LED preview (only when no device canvas) */}
        {!deviceConfig && <LEDPreview machineCtx={machineCtx} />}

        {/* Effect-specific parameters (rendered by json-render) */}
        <div className="space-y-4 p-4">
          <DynamicRenderer
            mode="json"
            spec={uiSpec}
            registry={effectRegistry}
            initialState={uiSpec.state}
            onStateChange={handleStateChange}
          />

          {/* Common: Speed slider */}
          <SpeedSlider machineCtx={machineCtx} speedConfig={speedConfig} />

          {/* Common: Play controls */}
          <PlayControls machineCtx={machineCtx} />
        </div>
      </div>
    </EffectMachineContext.Provider>
  )
}

// ── Public component ─────────────────────────────────────────

export default function EffectRenderer({ uiSpec, effectLogicCode, deviceConfig, onTick, bridgeConfig, speedConfig }: EffectRendererProps) {
  const createEffect = useCompiledCreateEffect(effectLogicCode)

  if (!createEffect) {
    return (
      <div className="p-5 text-center text-slate-600 dark:text-slate-400">
        <div className="inline-block h-10 w-10 rounded-full border-4 border-slate-300 border-t-sky-500 animate-spin dark:border-slate-700 dark:border-t-sky-400" />
        <p className="mt-2.5">Compiling effect logic...</p>
      </div>
    )
  }

  return (
    <EffectRendererInner
      createEffect={createEffect}
      uiSpec={uiSpec}
      deviceConfig={deviceConfig}
      onTick={onTick}
      bridgeConfig={bridgeConfig}
      speedConfig={speedConfig ?? DEFAULT_SPEED_CONFIG}
    />
  )
}

/**
 * Shared core logic for useEffectMachine.
 *
 * This module is framework-agnostic — it receives React hooks as parameters
 * so it can be used in normal React modules (EffectRenderer).
 */

import type { EffectMachine } from './EffectMachineContext'

// ── Types ────────────────────────────────────────────────────

export interface EffectMachineCoreResult {
  machine: EffectMachine
  speed: number
  isIdle: boolean
  isPaused: boolean
  handleStart(): void
  handlePauseResume(): void
  handleStop(): void
  handleSpeedChange(ms: number): void
  /** Subscribe to tick events. Returns an unsubscribe function. */
  subscribeTick(listener: () => void): () => void
}

/**
 * The React hooks that the core needs.
 * Callers provide these from whatever React instance they have access to.
 */
export interface ReactHooks {
  useRef: typeof import('react').useRef
  useState: typeof import('react').useState
  useCallback: typeof import('react').useCallback
  useEffect: typeof import('react').useEffect
}

export type CreateEffectFn = (config?: { ledCount?: number; speed?: number }) => EffectMachine

// ── Core implementation ──────────────────────────────────────

/**
 * Creates a `useEffectMachine` hook bound to the given React hooks.
 *
 * Usage:
 *   import { useRef, useState, useCallback, useEffect } from 'react'
 *   const useEffectMachine = createUseEffectMachine({ useRef, useState, useCallback, useEffect })
 */
export function createUseEffectMachine(hooks: ReactHooks) {
  return function useEffectMachine(
    createEffect: CreateEffectFn,
    config?: { ledCount?: number },
    onTick?: (leds: Uint8Array) => void,
  ): EffectMachineCoreResult {
    const machineRef = hooks.useRef<EffectMachine | null>(null)
    if (!machineRef.current) machineRef.current = createEffect(config)
    const machine = machineRef.current

    const onTickRef = hooks.useRef(onTick)
    onTickRef.current = onTick

    // Tick listeners — components (e.g. LEDPreview) subscribe to get notified
    // on each tick without triggering a parent re-render.
    const tickListenersRef = hooks.useRef(new Set<() => void>())

    const subscribeTick = hooks.useCallback((listener: () => void) => {
      tickListenersRef.current.add(listener)
      return () => { tickListenersRef.current.delete(listener) }
    }, [])

    // Status re-render: only triggered by user actions (start/stop/pause),
    // NOT by every tick.
    const [, setStatusVersion] = hooks.useState(0)
    const rerenderStatus = () => setStatusVersion((n: number) => n + 1)

    const [speed, setSpeedState] = hooks.useState(machine.speed)
    const intervalRef = hooks.useRef<number | null>(null)

    const clearTimer = hooks.useCallback(() => {
      if (intervalRef.current !== null) {
        clearInterval(intervalRef.current)
        intervalRef.current = null
      }
    }, [])

    const startTimer = hooks.useCallback(() => {
      clearTimer()
      intervalRef.current = window.setInterval(() => {
        machine.tick()
        if (onTickRef.current) onTickRef.current(machine.leds)
        // Notify tick subscribers (LEDPreview) instead of re-rendering the whole tree
        tickListenersRef.current.forEach((fn) => fn())
      }, machine.speed)
    }, [clearTimer, machine])

    hooks.useEffect(() => clearTimer, [clearTimer])

    const handleSpeedChange = hooks.useCallback(
      (ms: number) => {
        setSpeedState(ms)
        machine.setSpeed(ms)
        if (machine.status === 'running') startTimer()
      },
      [machine, startTimer],
    )

    const handleStart = hooks.useCallback(() => {
      machine.start()
      startTimer()
      rerenderStatus()
    }, [machine, startTimer])

    const handlePauseResume = hooks.useCallback(() => {
      if (machine.status === 'running') {
        machine.pause()
        clearTimer()
      } else if (machine.status === 'paused') {
        machine.resume()
        startTimer()
      }
      rerenderStatus()
    }, [machine, clearTimer, startTimer])

    const handleStop = hooks.useCallback(() => {
      machine.stop()
      clearTimer()
      rerenderStatus()
    }, [machine, clearTimer])

    return {
      machine,
      speed,
      isIdle: machine.status === 'idle',
      isPaused: machine.status === 'paused',
      handleStart,
      handlePauseResume,
      handleStop,
      handleSpeedChange,
      subscribeTick,
    }
  }
}

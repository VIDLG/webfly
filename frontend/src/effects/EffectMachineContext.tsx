import { createContext, useContext } from 'react'

/**
 * Represents the compiled createEffect function extracted from Babel-compiled effect code.
 */
export type CreateEffectFn = (config?: { ledCount?: number; speed?: number }) => EffectMachine

/**
 * The EffectMachine interface — matches the one declared in public/effects/globals.d.ts.
 * Re-declared here so the host app can reference it without depending on ambient globals.
 */
export interface EffectMachine {
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

export interface EffectMachineContextValue {
  machine: EffectMachine
  speed: number
  isIdle: boolean
  isPaused: boolean
  handleStart(): void
  handlePauseResume(): void
  handleStop(): void
  handleSpeedChange(ms: number): void
  subscribeTick(listener: () => void): () => void
}

export const EffectMachineContext = createContext<EffectMachineContextValue | null>(null)

export function useEffectMachineContext(): EffectMachineContextValue {
  const ctx = useContext(EffectMachineContext)
  if (!ctx) throw new Error('useEffectMachineContext must be used within an EffectMachineContext.Provider')
  return ctx
}

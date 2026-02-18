/**
 * Ambient type declarations for LED effect source files (effect.ts).
 *
 * These types describe the runtime globals provided by effect-runtime.ts
 * and the interfaces that effect.ts files must conform to.
 */

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

  // ── effect-runtime.ts — function implementations ─────────────

  function hsvToRgb(h: number, s: number, v: number): [number, number, number]
  function toRgb(color: TaggedColor): [number, number, number]
  function makeBlank(ledCount: number): Uint8Array
  function createBaseMachine(
    ledCount: number,
    speed: number,
    impl: {
      tick: (m: EffectMachine) => void
      reset: () => void
      setConfig: (key: string, value: unknown) => void
    },
  ): EffectMachine

  // ── {effect}/effect.ts ─────────────────────────────────────────

  function createEffect(config?: EffectBaseConfig): EffectMachine
}

export {}

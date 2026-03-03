/**
 * AIEffectController — interface between AI tools and the effect system.
 *
 * The LEDEffectPreviewPage creates a concrete controller that wires
 * tool actions to the actual EffectMachine and UI state.
 */

import type { Spec } from '@json-render/core'
import type { EffectBridgeConfig, SpeedConfig } from '../../effects/EffectRenderer.js'

export interface EffectState {
  uiSpec: Spec
  effectCode: string
  bridgeConfig?: EffectBridgeConfig
  speedConfig?: SpeedConfig
  /** Current runtime parameter values from json-render state */
  configValues: Record<string, unknown>
  /** Machine status: idle | running | paused */
  machineStatus: string
  /** Current speed in ms */
  speed: number
}

export interface AIEffectController {
  /** Get the current full state of the effect system */
  getState(): EffectState

  /** Set a single config parameter on the running machine */
  setConfig(key: string, value: unknown): void

  /** Change the speed of the running machine */
  setSpeed(ms: number): void

  /** Replace the UI spec (triggers DynamicRenderer re-render) */
  setUiSpec(spec: Spec): void

  /** Replace the bridge config */
  setBridgeConfig(config: EffectBridgeConfig): void

  /** Replace the effect code (triggers recompile + remount) */
  setEffectCode(code: string): void

  /** Get the runtime code (effect-runtime.ts content) for compilation */
  getRuntimeCode(): string
}

/**
 * modify_effect_code tool — rewrites the effect.ts logic with 3-layer validation.
 *
 * Validation layers:
 *   1. Babel compilation (syntax/type errors)
 *   2. Extract createEffect function (verify it exists)
 *   3. Smoke test — createEffect({ ledCount: 10 }), verify return has tick/start
 *
 * If any layer fails, the current effect is not affected and the error
 * is returned to the LLM for self-correction.
 */

import { tool } from 'ai'
import { z } from 'zod'
import * as ReactNamespace from 'react'
import { getBabelApi } from '../../components/DynamicRenderer.js'
import type { AIEffectController } from './types.js'
import { elementSchema } from '../schemas'

/**
 * Attempt to compile and validate effect code.
 * Returns { success, error? } without modifying any state.
 */
export function safeRecompileEffect(
  runtimeCode: string,
  effectCode: string,
): { success: true } | { success: false; error: string } {
  const fullCode = `${runtimeCode}\n\n${effectCode}`

  // Layer 1: Babel compilation
  let compiled: string
  try {
    const babelApi = getBabelApi()
    const result = babelApi.transform(fullCode, {
      filename: 'effect-logic.ts',
      presets: ['typescript'],
      plugins: ['transform-modules-commonjs'],
      sourceType: 'module',
    })
    if (!result.code) return { success: false, error: 'Babel compilation returned empty output' }
    compiled = result.code
  } catch (e) {
    return {
      success: false,
      error: `Babel compilation failed: ${e instanceof Error ? e.message : String(e)}`,
    }
  }

  // Layer 2: Extract createEffect function
  let createEffect: (config?: { ledCount?: number; speed?: number }) => unknown
  try {
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
      return { success: false, error: 'Could not extract createEffect function from code. Ensure the code defines a function named createEffect.' }
    }
    createEffect = extracted as typeof createEffect
  } catch (e) {
    return {
      success: false,
      error: `Failed to extract createEffect: ${e instanceof Error ? e.message : String(e)}`,
    }
  }

  // Layer 3: Smoke test
  try {
    const machine = createEffect({ ledCount: 10 }) as Record<string, unknown>
    const requiredMethods = ['tick', 'start', 'pause', 'resume', 'stop', 'setSpeed', 'setConfig']
    const missing = requiredMethods.filter((m) => typeof machine[m] !== 'function')
    if (missing.length > 0) {
      return { success: false, error: `Smoke test failed: machine is missing methods: ${missing.join(', ')}` }
    }
    if (!(machine.leds instanceof Uint8Array)) {
      return { success: false, error: 'Smoke test failed: machine.leds is not a Uint8Array' }
    }
  } catch (e) {
    return {
      success: false,
      error: `Smoke test failed: createEffect({ ledCount: 10 }) threw: ${e instanceof Error ? e.message : String(e)}`,
    }
  }

  return { success: true }
}


export function createModifyEffectTool(controller: AIEffectController) {
  return tool({
    description:
      'Rewrite the effect logic code (effect.ts). The code must define a ' +
      'createEffect function that returns an EffectMachine. ' +
      'Available runtime utilities: createBaseMachine, makeBlank, toRgb, hsvToRgb. ' +
      'The code will be validated (compiled + smoke tested) before being applied. ' +
      'If validation fails, the error is returned so you can fix and retry. ' +
      'Optionally provide new uiSpec and bridgeConfig to match the new logic.',
    inputSchema: z.object({
      effectCode: z.string().describe('The new effect.ts source code (TypeScript, no imports needed — runtime utilities are globally available)'),
      uiSpec: z.object({
        root: z.string(),
        elements: z.record(z.string(), elementSchema),
        state: z.record(z.string(), z.unknown()).optional(),
      }).optional().describe('Optional new UI spec to match the new effect logic'),
      bridgeConfig: z.object({
        colorKeys: z.array(z.string()).optional(),
        scaleKeys: z.record(z.string(), z.number()).optional(),
      }).optional().describe('Optional new bridge config'),
    }),
    execute: async ({ effectCode, uiSpec, bridgeConfig }) => {
      const runtimeCode = controller.getRuntimeCode()
      const validation = safeRecompileEffect(runtimeCode, effectCode)

      if (!validation.success) {
        return {
          success: false,
          error: validation.error,
          hint: 'Fix the error in the effect code and call modify_effect_code again.',
        }
      }

      // All layers passed — apply changes
      controller.setEffectCode(effectCode)
      if (uiSpec) {
        controller.setUiSpec(uiSpec as Parameters<typeof controller.setUiSpec>[0])
      }
      if (bridgeConfig) {
        controller.setBridgeConfig(bridgeConfig)
      }

      return { success: true, message: 'Effect code updated and validated successfully' }
    },
  })
}

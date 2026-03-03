/**
 * modify_ui tool — replaces the UI spec (json-render) for the effect.
 */

import { tool } from 'ai'
import { z } from 'zod'
import type { AIEffectController } from './types.js'
import { elementSchema } from '../schemas'

export function createModifyUiTool(controller: AIEffectController) {
  return tool({
    description:
      'Modify the effect UI by providing a new json-render UI spec. ' +
      'The spec defines the parameter controls shown to the user. ' +
      'Available component types: Stack, Card, CupertinoSlider, ColorHSV, Text. ' +
      'Use $bindState with paths like "/effect/paramName" for two-way binding. ' +
      'Optionally provide bridgeConfig to map UI state to effect machine config.',
    inputSchema: z.object({
      uiSpec: z.object({
        root: z.string().describe('ID of the root element'),
        elements: z.record(z.string(), elementSchema).describe('Element definitions keyed by element ID'),
        state: z.record(z.string(), z.unknown()).optional().describe('Initial state object'),
      }).describe('The json-render UI specification'),
      bridgeConfig: z.object({
        colorKeys: z.array(z.string()).optional(),
        scaleKeys: z.record(z.string(), z.number()).optional(),
      }).optional().describe('Optional bridge config mapping UI state to effect config'),
    }),
    execute: async ({ uiSpec, bridgeConfig }) => {
      try {
        controller.setUiSpec(uiSpec as Parameters<typeof controller.setUiSpec>[0])
        if (bridgeConfig) {
          controller.setBridgeConfig(bridgeConfig)
        }
        return { success: true, message: 'UI updated successfully' }
      } catch (e) {
        return {
          success: false,
          error: e instanceof Error ? e.message : String(e),
        }
      }
    },
  })
}

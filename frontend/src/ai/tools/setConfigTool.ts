/**
 * set_config tool — adjusts a single parameter on the running effect machine.
 */

import { tool } from 'ai'
import { z } from 'zod'
import type { AIEffectController } from './types.js'

export function createSetConfigTool(controller: AIEffectController) {
  return tool({
    description:
      'Adjust a single effect parameter (e.g. speed, hue, brightness). ' +
      'Use "speed" key to change animation speed in milliseconds. ' +
      'Other keys are effect-specific (e.g. "hueStep", "saturation").',
    inputSchema: z.object({
      key: z.string().describe('The parameter name to change'),
      value: z.union([z.number(), z.string(), z.boolean()])
        .describe('The new value for the parameter'),
    }),
    execute: async ({ key, value }) => {
      if (key === 'speed') {
        controller.setSpeed(value as number)
        return { success: true, message: `Speed set to ${value}ms` }
      }
      controller.setConfig(key, value)
      return { success: true, message: `Set ${key} = ${JSON.stringify(value)}` }
    },
  })
}

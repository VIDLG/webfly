export type LedEffectId = 'wave' | 'blink' | 'chase' | 'rainbow'

export interface LedEffectManifest {
  id: LedEffectId
  name: string
  description: string
}

export const LED_EFFECTS: LedEffectManifest[] = [
  {
    id: 'wave',
    name: '🌊 Wave',
    description: 'A group of adjacent LEDs moving together like a wave',
  },
  {
    id: 'blink',
    name: '💫 Blink',
    description: 'All LEDs blink in sync',
  },
  {
    id: 'chase',
    name: '🏃 Chase',
    description: 'LEDs chasing each other in a loop',
  },
  {
    id: 'rainbow',
    name: '🌈 Rainbow',
    description: 'Cycling rainbow colors across the LED strip',
  },
]

export const KNOWN_EFFECT_IDS = LED_EFFECTS.map((e) => e.id)

export function getEffectManifest(effectId: string): LedEffectManifest | undefined {
  return LED_EFFECTS.find((e) => e.id === effectId)
}


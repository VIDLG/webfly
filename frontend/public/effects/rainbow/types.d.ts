declare global {
  interface RainbowEffectConfig extends EffectBaseConfig {
    hueStep?: number
    hueSpread?: number
    saturation?: number
    brightness?: number
  }
}

export {}

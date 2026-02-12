declare global {
  interface WaveEffectConfig extends EffectBaseConfig {
    color?: TaggedColor
    waveWidth?: number
  }
}

export {}

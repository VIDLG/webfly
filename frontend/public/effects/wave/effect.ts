/**
 * Wave effect – a group of adjacent LEDs slides across the strip each tick.
 */
interface WaveEffectConfig extends EffectBaseConfig {
  color?: TaggedColor
  waveWidth?: number
}

function createEffect(config?: WaveEffectConfig): EffectMachine {
  const cfg = config || {} as WaveEffectConfig;
  const ledCount = cfg.ledCount || 20;
  let color = toRgb(cfg.color || { mode: 'rgb', r: 52, g: 211, b: 153 });
  let waveWidth = cfg.waveWidth || 5;
  let position = 0;

  return createBaseMachine(ledCount, cfg.speed || 100, {
    tick: function (m: EffectMachine) {
      const buf = makeBlank(ledCount);
      for (let i = 0; i < waveWidth; i++) {
        const o = ((position + i) % ledCount) * 3;
        buf[o] = color[0]; buf[o + 1] = color[1]; buf[o + 2] = color[2];
      }
      m.leds = buf;
      position = (position + 1) % ledCount;
    },
    reset: function () { position = 0; },
    setConfig: function (key: string, value: unknown) {
      if (key === 'color') color = toRgb(value as TaggedColor);
      if (key === 'waveWidth') waveWidth = value as number;
    }
  });
}

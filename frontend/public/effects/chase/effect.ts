/**
 * Chase effect – multiple LEDs (evenly spaced) chase around the ring each tick.
 */
interface ChaseEffectConfig extends EffectBaseConfig {
  color?: TaggedColor
  chaseCount?: number
}

function createEffect(config?: ChaseEffectConfig): EffectMachine {
  const cfg = config || {} as ChaseEffectConfig;
  const ledCount = cfg.ledCount || 20;
  let color = toRgb(cfg.color || { mode: 'rgb', r: 251, g: 191, b: 36 });
  let chaseCount = cfg.chaseCount || 2;
  let position = 0;

  return createBaseMachine(ledCount, cfg.speed || 80, {
    tick: function (m: EffectMachine) {
      const buf = makeBlank(ledCount);
      const gap = Math.floor(ledCount / chaseCount);
      for (let i = 0; i < chaseCount; i++) {
        const o = ((position + gap * i) % ledCount) * 3;
        buf[o] = color[0]; buf[o + 1] = color[1]; buf[o + 2] = color[2];
      }
      m.leds = buf;
      position = (position + 1) % ledCount;
    },
    reset: function () { position = 0; },
    setConfig: function (key: string, value: unknown) {
      if (key === 'color') color = toRgb(value as TaggedColor);
      if (key === 'chaseCount') chaseCount = value as number;
    }
  });
}

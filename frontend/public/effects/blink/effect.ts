/**
 * Blink effect – all LEDs toggle on/off in unison each tick.
 */
interface BlinkEffectConfig extends EffectBaseConfig {
  color?: TaggedColor
}

function createEffect(config?: BlinkEffectConfig): EffectMachine {
  const cfg = config || {} as BlinkEffectConfig;
  const ledCount = cfg.ledCount || 20;
  let color = toRgb(cfg.color || { mode: 'rgb', r: 217, g: 70, b: 239 });
  let on = false;

  return createBaseMachine(ledCount, cfg.speed || 200, {
    tick: function (m: EffectMachine) {
      on = !on;
      const buf = makeBlank(ledCount);
      if (on) {
        for (let i = 0; i < ledCount; i++) {
          const o = i * 3;
          buf[o] = color[0]; buf[o + 1] = color[1]; buf[o + 2] = color[2];
        }
      }
      m.leds = buf;
    },
    reset: function () { on = false; },
    setConfig: function (key: string, value: unknown) {
      if (key === 'color') color = toRgb(value as TaggedColor);
    }
  });
}

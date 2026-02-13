/**
 * Rainbow effect – each LED gets a hue offset; the hue cycles forward each tick.
 */
interface RainbowEffectConfig extends EffectBaseConfig {
  hueStep?: number
  hueSpread?: number
  saturation?: number
  brightness?: number
}

function createEffect(config?: RainbowEffectConfig): EffectMachine {
  const cfg = config || {} as RainbowEffectConfig;
  const ledCount = cfg.ledCount || 20;
  let hueStep = cfg.hueStep || 10;
  let hueSpread = cfg.hueSpread || 18;
  let saturation = cfg.saturation != null ? cfg.saturation : 1;
  let brightness = cfg.brightness != null ? cfg.brightness : 1;
  let offset = 0;

  return createBaseMachine(ledCount, cfg.speed || 100, {
    tick: function (m: EffectMachine) {
      const buf = makeBlank(ledCount);
      for (let i = 0; i < ledCount; i++) {
        const hue = (i * hueSpread + offset) % 360;
        const rgb = hsvToRgb(hue, saturation, brightness);
        const o = i * 3;
        buf[o] = rgb[0]; buf[o + 1] = rgb[1]; buf[o + 2] = rgb[2];
      }
      m.leds = buf;
      offset = (offset + hueStep) % 360;
    },
    reset: function () { offset = 0; },
    setConfig: function (key: string, value: unknown) {
      if (key === 'hueStep') hueStep = value as number;
      if (key === 'hueSpread') hueSpread = value as number;
      if (key === 'saturation') saturation = value as number;
      if (key === 'brightness') brightness = value as number;
    }
  });
}

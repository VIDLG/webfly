/**
 * Wave effect – a group of adjacent LEDs slides across the strip each tick.
 *
 * Config:
 *   ledCount  - number of LEDs (default 20)
 *   speed     - ms per tick (default 100)
 *   color     - tagged color (default emerald)
 *   waveWidth - how many LEDs are lit simultaneously (default 5)
 */
function createEffect(config) {
  config = config || {};
  var ledCount = config.ledCount || 20;
  var color = toRgb(config.color || { mode: 'rgb', r: 52, g: 211, b: 153 });
  var waveWidth = config.waveWidth || 5;
  var position = 0;

  return createBaseMachine(ledCount, config.speed || 100, {
    tick: function (m) {
      var buf = makeBlank(ledCount);
      for (var i = 0; i < waveWidth; i++) {
        var o = ((position + i) % ledCount) * 3;
        buf[o] = color[0]; buf[o + 1] = color[1]; buf[o + 2] = color[2];
      }
      m.leds = buf;
      position = (position + 1) % ledCount;
    },
    reset: function () { position = 0; },
    setConfig: function (key, value) {
      if (key === 'color') color = toRgb(value);
      if (key === 'waveWidth') waveWidth = value;
    }
  });
}

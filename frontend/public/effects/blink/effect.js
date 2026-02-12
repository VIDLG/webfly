/**
 * Blink effect – all LEDs toggle on/off in unison each tick.
 *
 * Config:
 *   ledCount - number of LEDs (default 20)
 *   speed    - ms per tick (default 200)
 *   color    - tagged color (default fuchsia)
 */
function createEffect(config) {
  config = config || {};
  var ledCount = config.ledCount || 20;
  var color = toRgb(config.color || { mode: 'rgb', r: 217, g: 70, b: 239 });
  var on = false;

  return createBaseMachine(ledCount, config.speed || 200, {
    tick: function (m) {
      on = !on;
      var buf = makeBlank(ledCount);
      if (on) {
        for (var i = 0; i < ledCount; i++) {
          var o = i * 3;
          buf[o] = color[0]; buf[o + 1] = color[1]; buf[o + 2] = color[2];
        }
      }
      m.leds = buf;
    },
    reset: function () { on = false; },
    setConfig: function (key, value) {
      if (key === 'color') color = toRgb(value);
    }
  });
}

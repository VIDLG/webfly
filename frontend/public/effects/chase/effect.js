/**
 * Chase effect – multiple LEDs (evenly spaced) chase around the ring each tick.
 *
 * Config:
 *   ledCount   - number of LEDs (default 20)
 *   speed      - ms per tick (default 80)
 *   color      - tagged color (default amber)
 *   chaseCount - number of lit chase points (default 2)
 */
function createEffect(config) {
  config = config || {};
  var ledCount = config.ledCount || 20;
  var color = toRgb(config.color || { mode: 'rgb', r: 251, g: 191, b: 36 });
  var chaseCount = config.chaseCount || 2;
  var position = 0;

  return createBaseMachine(ledCount, config.speed || 80, {
    tick: function (m) {
      var buf = makeBlank(ledCount);
      var gap = Math.floor(ledCount / chaseCount);
      for (var i = 0; i < chaseCount; i++) {
        var o = ((position + gap * i) % ledCount) * 3;
        buf[o] = color[0]; buf[o + 1] = color[1]; buf[o + 2] = color[2];
      }
      m.leds = buf;
      position = (position + 1) % ledCount;
    },
    reset: function () { position = 0; },
    setConfig: function (key, value) {
      if (key === 'color') color = toRgb(value);
      if (key === 'chaseCount') chaseCount = value;
    }
  });
}

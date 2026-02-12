/**
 * Rainbow effect – each LED gets a hue offset; the hue cycles forward each tick.
 *
 * Config:
 *   ledCount   - number of LEDs (default 20)
 *   speed      - ms per tick (default 100)
 *   hueStep    - degrees the hue advances per tick (default 10)
 *   hueSpread  - hue degree gap between adjacent LEDs (default 18)
 *   saturation - HSV saturation 0-1 (default 1)
 *   brightness - HSV value/brightness 0-1 (default 1)
 */
function createEffect(config) {
  config = config || {};
  var ledCount = config.ledCount || 20;
  var hueStep = config.hueStep || 10;
  var hueSpread = config.hueSpread || 18;
  var saturation = config.saturation != null ? config.saturation : 1;
  var brightness = config.brightness != null ? config.brightness : 1;
  var offset = 0;

  return createBaseMachine(ledCount, config.speed || 100, {
    tick: function (m) {
      var buf = makeBlank(ledCount);
      for (var i = 0; i < ledCount; i++) {
        var hue = (i * hueSpread + offset) % 360;
        var rgb = hsvToRgb(hue, saturation, brightness);
        var o = i * 3;
        buf[o] = rgb[0]; buf[o + 1] = rgb[1]; buf[o + 2] = rgb[2];
      }
      m.leds = buf;
      offset = (offset + hueStep) % 360;
    },
    reset: function () { offset = 0; },
    setConfig: function (key, value) {
      if (key === 'hueStep') hueStep = value;
      if (key === 'hueSpread') hueSpread = value;
      if (key === 'saturation') saturation = value;
      if (key === 'brightness') brightness = value;
    }
  });
}

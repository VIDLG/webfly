/**
 * Shared LED effect utilities.
 *
 * Color types (tagged):
 *   { mode: 'rgb', r, g, b }   – 0-255 per channel
 *   { mode: 'hsv', h, s, v }   – h: 0-360, s/v: 0-1
 *
 * leds buffer: Uint8Array of length ledCount*3, layout [R,G,B, R,G,B, ...]
 */

/** Convert HSV (h 0-360, s/v 0-1) to [r, g, b] tuple. */
function hsvToRgb(h, s, v) {
  h = ((h % 360) + 360) % 360;
  var c = v * s;
  var x = c * (1 - Math.abs(((h / 60) % 2) - 1));
  var m = v - c;
  var r = 0, g = 0, b = 0;
  if (h < 60)       { r = c; g = x; }
  else if (h < 120) { r = x; g = c; }
  else if (h < 180) { g = c; b = x; }
  else if (h < 240) { g = x; b = c; }
  else if (h < 300) { r = x; b = c; }
  else              { r = c; b = x; }
  return [Math.round((r + m) * 255), Math.round((g + m) * 255), Math.round((b + m) * 255)];
}

/** Convert a tagged color ({ mode:'rgb' } or { mode:'hsv' }) to [r, g, b] tuple. */
function toRgb(c) {
  if (c.mode === 'hsv') return hsvToRgb(c.h, c.s, c.v);
  return [c.r, c.g, c.b];
}

/** Create a zeroed Uint8Array for ledCount LEDs (3 bytes each). */
function makeBlank(ledCount) {
  return new Uint8Array(ledCount * 3);
}

/**
 * Create a base LED state machine with common lifecycle methods.
 *
 * @param {number} ledCount  – number of LEDs
 * @param {number} speed     – ms per tick
 * @param {object} handlers  – effect-specific callbacks:
 *   tick(machine)          – compute one frame, set machine.leds
 *   reset()                – reset internal state on stop
 *   setConfig(key, value)  – handle effect-specific config updates
 *
 * Returns a machine object with:
 *   status, speed, ledCount, leds,
 *   tick(), start(), pause(), resume(), stop(),
 *   setSpeed(ms), setConfig(key, value)
 */
function createBaseMachine(ledCount, speed, handlers) {
  var machine = {
    status: 'idle',
    speed: speed,
    ledCount: ledCount,
    leds: makeBlank(ledCount),

    tick: function () {
      if (machine.status !== 'running') return;
      handlers.tick(machine);
    },

    start: function () {
      if (machine.status === 'idle') machine.status = 'running';
    },
    pause: function () {
      if (machine.status === 'running') machine.status = 'paused';
    },
    resume: function () {
      if (machine.status === 'paused') machine.status = 'running';
    },
    stop: function () {
      machine.status = 'idle';
      if (handlers.reset) handlers.reset();
      machine.leds = makeBlank(ledCount);
    },

    setSpeed: function (ms) { machine.speed = ms; },
    setConfig: function (key, value) {
      if (key === 'speed') machine.speed = value;
      else if (handlers.setConfig) handlers.setConfig(key, value);
    }
  };

  return machine;
}
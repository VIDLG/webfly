# webfly-effect-dev

Create new LED effects for the WebFly effect system. Each effect is a self-contained directory with metadata, UI specification, and runtime logic.

## When to Use

- Adding a new LED animation effect
- Modifying an existing effect's behavior or UI
- Understanding the effect runtime API

## Directory Structure

```
frontend/public/effects/
├── effect-runtime.ts      # Shared runtime (DO NOT MODIFY)
├── globals.d.ts           # Type declarations
├── manifest.json          # Effect registry (add new effects here)
└── <effect-id>/
    ├── meta.json           # Metadata
    ├── ui.json             # UI specification (json-render)
    └── effect.ts           # Effect logic
```

## Step-by-Step Guide

### 1. Create Effect Directory

```bash
mkdir frontend/public/effects/<effect-id>
```

### 2. meta.json

```json
{
  "id": "<effect-id>",
  "name": "Display Name",
  "description": "Short description of what this effect does"
}
```

### 3. effect.ts

Every effect must export a `createEffect` function:

```typescript
function createEffect(config?: EffectBaseConfig): EffectMachine {
  const ledCount = config?.ledCount ?? 86;
  const speed = config?.speed ?? 50;

  // Local state
  let offset = 0;
  let color: TaggedColor = { mode: 'hsv', h: 0, s: 1, v: 1 };

  return createBaseMachine(ledCount, speed, {
    tick(machine) {
      // Update machine.leds buffer on each tick
      // Buffer format: Uint8Array [R0,G0,B0, R1,G1,B1, ...]
      const [r, g, b] = toRgb(color);
      for (let i = 0; i < machine.ledCount; i++) {
        const idx = i * 3;
        // Your animation logic here
        machine.leds[idx] = r;
        machine.leds[idx + 1] = g;
        machine.leds[idx + 2] = b;
      }
      offset++;
    },
    reset() {
      offset = 0;
    },
    setConfig(key, value) {
      if (key === 'color') color = value as TaggedColor;
    },
  });
}
```

### 4. ui.json

Defines the effect's parameter UI using json-render format:

```json
{
  "root": "main-card",
  "bridge": {
    "colorKeys": ["hue", "saturation", "brightness"],
    "scaleKeys": { "saturation": 0.01, "brightness": 0.01 }
  },
  "speed": { "min": 20, "max": 500, "default": 50 },
  "state": {
    "effect": {
      "hue": 200,
      "saturation": 100,
      "brightness": 100
    }
  },
  "elements": {
    "main-card": {
      "type": "Card",
      "props": { "title": "Effect Name" },
      "children": ["color-picker"]
    },
    "color-picker": {
      "type": "ColorHSV",
      "props": {
        "label": "Color",
        "hue": { "$bindState": "/effect/hue" },
        "saturation": { "$bindState": "/effect/saturation" },
        "brightness": { "$bindState": "/effect/brightness" }
      }
    }
  }
}
```

### 5. Register in manifest.json

Add the effect ID to `frontend/public/effects/manifest.json`:

```json
["blink", "wave", "chase", "rainbow", "<your-effect-id>"]
```

## Runtime API

Available globals in `effect.ts` (provided by effect-runtime.ts):

| Function | Signature | Description |
|----------|-----------|-------------|
| `createBaseMachine` | `(ledCount, speed, handlers) => EffectMachine` | Create state machine with tick/reset/setConfig handlers |
| `makeBlank` | `(ledCount) => Uint8Array` | Create zeroed RGB buffer (ledCount * 3 bytes) |
| `hsvToRgb` | `(h: 0-360, s: 0-1, v: 0-1) => [r, g, b]` | HSV to RGB conversion |
| `toRgb` | `(color: TaggedColor) => [r, g, b]` | Convert tagged color to RGB tuple |

## LED Buffer Format

- Type: `Uint8Array`, size: `ledCount * 3`
- Layout: `[R0, G0, B0, R1, G1, B1, ...]`
- Values: 0-255 per channel
- Access: `machine.leds[i * 3]` = R, `[i * 3 + 1]` = G, `[i * 3 + 2]` = B

## EffectMachine Lifecycle

```
  idle ──start()──▶ running ──pause()──▶ paused
   ▲                  │                    │
   └────stop()────────┴────stop()──────────┘
                              resume()
                      paused ──────────▶ running
```

- `tick()`: Called at `speed` ms intervals while running
- `setConfig(key, value)`: Called when UI state changes
- `reset()`: Called on stop, reset local state

## UI Components

| Type | Props | Description |
|------|-------|-------------|
| `Stack` | `direction`, `gap` | Flexbox container |
| `Card` | `title` | Bordered card |
| `CupertinoSlider` | `label`, `min`, `max`, `value`, `unit`, `accentColor` | Flutter slider |
| `ColorHSV` | `label`, `hue`, `saturation`, `brightness`, `accentColor` | 3-slider HSV picker |
| `Text` | `text`, `variant` | Static text |

State binding: `{ "$bindState": "/effect/key" }` binds a prop to the state tree.

## Bridge Config

The `bridge` section in ui.json maps UI state to `setConfig()` calls:

- `colorKeys`: Array of state keys forming HSV color → merged into `setConfig('color', { mode: 'hsv', h, s, v })`
- `scaleKeys`: Scale factors applied before passing (e.g., `{"saturation": 0.01}` converts 0-100 slider to 0-1)

## Checklist

- [ ] `meta.json` with id, name, description
- [ ] `effect.ts` exports `createEffect` function
- [ ] `createEffect` returns result of `createBaseMachine()`
- [ ] `ui.json` defines parameter UI with state bindings
- [ ] Effect ID added to `manifest.json`
- [ ] `setConfig` handles all UI-bound parameters
- [ ] `reset()` clears all local state

import { type ReactNode, useMemo } from 'react'
import { defineRegistry, useBoundProp } from '@json-render/react'
import { FlutterCupertinoSlider } from '@openwebf/react-cupertino-ui'
import { useTheme } from '../hooks/theme'
import { effectCatalog } from './catalog'

// ── Helpers ──────────────────────────────────────────────────

function hsvToRgb(h: number, s: number, v: number): [number, number, number] {
  h = ((h % 360) + 360) % 360
  const c = v * s
  const x = c * (1 - Math.abs(((h / 60) % 2) - 1))
  const m = v - c
  let r = 0,
    g = 0,
    b = 0
  if (h < 60) {
    r = c
    g = x
  } else if (h < 120) {
    r = x
    g = c
  } else if (h < 180) {
    g = c
    b = x
  } else if (h < 240) {
    g = x
    b = c
  } else if (h < 300) {
    r = x
    b = c
  } else {
    r = c
    b = x
  }
  return [Math.round((r + m) * 255), Math.round((g + m) * 255), Math.round((b + m) * 255)]
}

const gapMap = { sm: '0.5rem', md: '1rem', lg: '1.5rem' } as const

/**
 * Wrapper around FlutterCupertinoSlider that accepts `activeColor` prop.
 * The underlying custom element supports `activeColor` at runtime but the
 * TypeScript declarations don't include it, so we pass it via a spread.
 */
function CupertinoSliderWidget({
  val,
  min,
  max,
  step,
  activeColor,
  onChange,
}: {
  val: number
  min: number
  max: number
  step?: number
  activeColor?: string
  onChange: (e: CustomEvent<number>) => void
}) {
  // Build extra props that the TS types don't declare or that must be
  // conditionally omitted (WebF custom elements treat `undefined` props
  // differently from absent props – e.g. step=undefined → divisions=0).
  const extra: Record<string, unknown> = {}
  if (activeColor) extra.activeColor = activeColor
  if (step != null && step > 0) extra.step = step
  return (
    <FlutterCupertinoSlider
      val={val}
      min={min}
      max={max}
      onChange={onChange}
      {...extra}
    />
  )
}

// ── Registry ─────────────────────────────────────────────────

export const { registry: effectRegistry } = defineRegistry(effectCatalog, {
  components: {
    // ── Stack ──────────────────────────────────────────────
    Stack: ({ props, children }) => {
      const dir = props.direction ?? 'vertical'
      const gap = props.gap ? gapMap[props.gap] : undefined
      return (
        <div
          style={{
            display: 'flex',
            flexDirection: dir === 'horizontal' ? 'row' : 'column',
            gap,
          }}
        >
          {children}
        </div>
      )
    },

    // ── Card ───────────────────────────────────────────────
    Card: ({ props, children }) => (
      <div className="rounded-xl border border-slate-200 bg-white/70 p-4 dark:border-slate-800 dark:bg-slate-900/60 space-y-4">
        {props.title && (
          <label className="text-sm font-bold text-slate-600 dark:text-slate-400">{props.title}</label>
        )}
        {children}
      </div>
    ),

    // ── CupertinoSlider ────────────────────────────────────
    CupertinoSlider: ({ props, bindings }) => {
      const [value, setValue] = useBoundProp<number>(props.value ?? 0, bindings?.value)
      const dark = useTheme().theme === 'dark'
      const accent = props.accentColor ?? (dark ? '#60a5fa' : '#3b82f6')

      return (
        <div>
          <div className="flex justify-between items-center mb-2">
            <label className="text-sm font-bold text-slate-600 dark:text-slate-400">{props.label}</label>
            <span className="rounded-md border border-slate-300 bg-white px-3 py-1 font-mono text-xs dark:border-slate-700 dark:bg-slate-900/60" style={{ color: accent }}>
              {Math.round(value ?? 0)}
              {props.unit ?? ''}
            </span>
          </div>
          <CupertinoSliderWidget
            min={props.min}
            max={props.max}
            step={props.step ?? undefined}
            val={value ?? props.min}
            onChange={(e) => setValue(e.detail)}
            activeColor={accent}
          />
          {(props.minLabel || props.maxLabel) && (
            <div className="flex justify-between text-[11px] text-slate-600 dark:text-slate-400 font-medium px-1 mt-2 uppercase tracking-wide">
              <span>{props.minLabel ?? ''}</span>
              <span>{props.maxLabel ?? ''}</span>
            </div>
          )}
        </div>
      )
    },

    // ── ColorHSV ───────────────────────────────────────────
    ColorHSV: ({ props, bindings }) => {
      const [hue, setHue] = useBoundProp<number>(props.hue ?? 0, bindings?.hue)
      const [sat, setSat] = useBoundProp<number>(props.saturation ?? 100, bindings?.saturation)
      const [bri, setBri] = useBoundProp<number>(props.brightness ?? 100, bindings?.brightness)
      const accent = props.accentColor

      const previewRgb = useMemo(
        () => hsvToRgb(hue ?? 0, (sat ?? 100) / 100, (bri ?? 100) / 100),
        [hue, sat, bri],
      )
      const previewColor = `rgb(${previewRgb[0]},${previewRgb[1]},${previewRgb[2]})`
      const textColor = accent ?? previewColor

      return (
        <div className="rounded-xl border border-slate-200 bg-white/70 p-4 dark:border-slate-800 dark:bg-slate-900/60 space-y-4">
          <div className="flex items-center gap-3 mb-1">
            <div
              className="w-8 h-8 rounded-full border-2 border-slate-300 dark:border-slate-600"
              style={{ backgroundColor: previewColor }}
            />
            <label className="text-sm font-bold text-slate-600 dark:text-slate-400">{props.label}</label>
          </div>

          {/* Hue */}
          <div>
            <div className="flex justify-between items-center mb-2">
              <label className="text-sm font-bold text-slate-600 dark:text-slate-400">Hue</label>
              <span className="rounded-md border border-slate-300 bg-white px-3 py-1 font-mono text-xs dark:border-slate-700 dark:bg-slate-900/60" style={{ color: textColor }}>
                {Math.round(hue ?? 0)}&deg;
              </span>
            </div>
            <CupertinoSliderWidget
              min={0}
              max={360}
              val={hue ?? 0}
              onChange={(e) => setHue(e.detail)}
              activeColor={previewColor}
            />
          </div>

          {/* Saturation */}
          <div>
            <div className="flex justify-between items-center mb-2">
              <label className="text-sm font-bold text-slate-600 dark:text-slate-400">Saturation</label>
              <span className="rounded-md border border-slate-300 bg-white px-3 py-1 font-mono text-xs dark:border-slate-700 dark:bg-slate-900/60" style={{ color: textColor }}>
                {Math.round(sat ?? 100)}%
              </span>
            </div>
            <CupertinoSliderWidget
              min={0}
              max={100}
              val={sat ?? 100}
              onChange={(e) => setSat(e.detail)}
              activeColor={previewColor}
            />
          </div>

          {/* Brightness */}
          <div>
            <div className="flex justify-between items-center mb-2">
              <label className="text-sm font-bold text-slate-600 dark:text-slate-400">Brightness</label>
              <span className="rounded-md border border-slate-300 bg-white px-3 py-1 font-mono text-xs dark:border-slate-700 dark:bg-slate-900/60" style={{ color: textColor }}>
                {Math.round(bri ?? 100)}%
              </span>
            </div>
            <CupertinoSliderWidget
              min={0}
              max={100}
              val={bri ?? 100}
              onChange={(e) => setBri(e.detail)}
              activeColor={previewColor}
            />
          </div>
        </div>
      )
    },

    // ── Text ───────────────────────────────────────────────
    Text: ({ props }) => {
      const variantClass =
        props.variant === 'label'
          ? 'text-sm font-bold text-slate-600 dark:text-slate-400'
          : props.variant === 'value'
            ? 'font-mono text-xs'
            : props.variant === 'hint'
              ? 'text-[11px] text-slate-600 dark:text-slate-400 font-medium uppercase tracking-wide'
              : 'text-sm text-slate-700 dark:text-slate-300'
      return <span className={variantClass}>{props.text}</span>
    },
  },
}) as { registry: ReturnType<typeof defineRegistry>['registry'] }

// Re-export for convenience
export type { ReactNode }

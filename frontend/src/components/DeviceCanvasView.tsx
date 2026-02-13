import React, { useEffect, useRef } from 'react'
import { useFlutterAttached } from '@openwebf/react-core-ui'
import { isWebFEnvironment } from '../utils/environment'
import { useTheme } from '../hooks/theme'
import type { DeviceConfig } from '../types/device'

interface DeviceCanvasViewProps {
  deviceConfig: DeviceConfig
  ledBufferRef: React.RefObject<Uint8Array | null>
}

/** Padding around the device in mm, added to all sides. */
const PADDING_MM = 15

export default function DeviceCanvasView({ deviceConfig, ledBufferRef }: DeviceCanvasViewProps) {
  const { theme } = useTheme()
  const dark = theme === 'dark'

  // ── coordinate mapping ────────────────────────────────────────
  // Device config uses center-origin mm coordinates (y+ = forward/up on drone).
  // Canvas pixel coordinates: top-left origin, y increases downward.
  const canvasW = deviceConfig.canvas.width + PADDING_MM * 2
  const canvasH = deviceConfig.canvas.height + PADDING_MM * 2

  // ── animation loop ────────────────────────────────────────────
  // Only redraw when the LED buffer actually changes to avoid flooding
  // WebF's Canvas2D debug logging with continuous draw calls.
  const POLL_INTERVAL_MS = 50
  const timerRef = useRef(0)
  const lastBufSnapshotRef = useRef('')

  /** Cheap fingerprint of the current LED buffer to detect changes. */
  const bufferSnapshot = (): string => {
    const buf = ledBufferRef.current
    if (!buf || buf.length === 0) return ''
    // Sample a few bytes instead of hashing the entire buffer
    const len = buf.length
    return `${buf[0]},${buf[Math.floor(len / 4)]},${buf[Math.floor(len / 2)]},${buf[len - 1]}`
  }

  const drawFrame = (ctx: CanvasRenderingContext2D, cssW: number, cssH: number) => {
    const scale = Math.min(cssW / canvasW, cssH / canvasH)
    const offsetX = (cssW - canvasW * scale) / 2
    const offsetY = (cssH - canvasH * scale) / 2

    /** Convert mm (center origin, y-up) to canvas px (top-left origin, y-down). */
    const toPixel = (xMm: number, yMm: number): [number, number] => {
      const px = offsetX + (xMm + canvasW / 2) * scale
      const py = offsetY + (canvasH / 2 - yMm) * scale
      return [px, py]
    }

    ctx.clearRect(0, 0, cssW, cssH)

    // ── background ────────────────────────────────────────────
    ctx.fillStyle = dark ? '#0f172a' : '#f8fafc'
    ctx.fillRect(0, 0, cssW, cssH)

    // ── rotor guards ──────────────────────────────────────────
    if (deviceConfig.rotorGuards) {
      ctx.strokeStyle = dark ? 'rgba(148,163,184,0.35)' : 'rgba(100,116,139,0.3)'
      ctx.lineWidth = 1.5
      for (const guard of Object.values(deviceConfig.rotorGuards)) {
        const [cx, cy] = toPixel(guard.cx, guard.cy)
        const r = guard.radius * scale
        ctx.beginPath()
        ctx.arc(cx, cy, r, 0, Math.PI * 2)
        ctx.stroke()
      }
    }

    // ── drone body hint (small rectangle at center) ───────────
    {
      const [bx, by] = toPixel(-8, -6)
      const [bx2, by2] = toPixel(8, 6)
      ctx.fillStyle = dark ? 'rgba(148,163,184,0.15)' : 'rgba(100,116,139,0.12)'
      ctx.fillRect(bx, by2, bx2 - bx, by - by2)
    }

    // ── LEDs ──────────────────────────────────────────────────
    const buf = ledBufferRef.current
    const ledRadius = Math.max(2, 2.5 * scale)

    // Compute strip start offsets (each strip's leds are indexed from 0,
    // but in the buffer they're laid out sequentially across strips).
    let bufOffset = 0
    for (const strip of deviceConfig.strips) {
      for (const led of strip.leds) {
        const idx = bufOffset + led.index
        const o = idx * 3
        const r = buf ? buf[o] ?? 0 : 0
        const g = buf ? buf[o + 1] ?? 0 : 0
        const b = buf ? buf[o + 2] ?? 0 : 0
        const lit = r > 0 || g > 0 || b > 0

        const [px, py] = toPixel(led.x, led.y)

        if (lit) {
          // Glow
          ctx.beginPath()
          ctx.arc(px, py, ledRadius * 1.8, 0, Math.PI * 2)
          ctx.fillStyle = `rgba(${r},${g},${b},0.25)`
          ctx.fill()

          // Core
          ctx.beginPath()
          ctx.arc(px, py, ledRadius, 0, Math.PI * 2)
          ctx.fillStyle = `rgb(${r},${g},${b})`
          ctx.fill()
        } else {
          // Unlit dot
          ctx.beginPath()
          ctx.arc(px, py, ledRadius * 0.7, 0, Math.PI * 2)
          ctx.fillStyle = dark ? 'rgba(148,163,184,0.25)' : 'rgba(100,116,139,0.2)'
          ctx.fill()
        }
      }
      bufOffset += strip.ledCount
    }

    // ── "FRONT" direction label ───────────────────────────────
    {
      const [fx, fy] = toPixel(0, canvasH / 2 - PADDING_MM / 2)
      ctx.fillStyle = dark ? 'rgba(148,163,184,0.5)' : 'rgba(100,116,139,0.5)'
      ctx.font = `${Math.max(10, 11 * scale)}px sans-serif`
      ctx.textAlign = 'center'
      ctx.textBaseline = 'middle'
      ctx.fillText('FRONT', fx, fy)
    }
  }

  // ── canvas setup (WebF + browser dual-ref pattern) ──────────
  const startAnimation = (canvasEl: HTMLCanvasElement) => {
    const ctx = canvasEl.getContext('2d')
    if (!ctx) return

    const dpr = window.devicePixelRatio || 1
    const rect = canvasEl.getBoundingClientRect()
    if (!rect || !rect.width || !rect.height) return
    canvasEl.width = rect.width * dpr
    canvasEl.height = rect.height * dpr
    ctx.scale(dpr, dpr)

    const cssW = rect.width
    const cssH = rect.height

    stopAnimation()
    drawFrame(ctx, cssW, cssH) // first frame immediately
    lastBufSnapshotRef.current = bufferSnapshot()
    timerRef.current = window.setInterval(() => {
      const snap = bufferSnapshot()
      if (snap !== lastBufSnapshotRef.current) {
        lastBufSnapshotRef.current = snap
        drawFrame(ctx, cssW, cssH)
      }
    }, POLL_INTERVAL_MS)
  }

  const stopAnimation = () => {
    if (timerRef.current) {
      clearInterval(timerRef.current)
      timerRef.current = 0
    }
  }

  // WebF path: useFlutterAttached fires onAttached when the canvas is ready
  const onAttached = (element: HTMLCanvasElement | Event) => {
    const canvasEl = (element instanceof Event ? element.target : element) as HTMLCanvasElement
    startAnimation(canvasEl)
  }

  const onDetached = () => {
    stopAnimation()
  }

  const flutterCanvasRef = useFlutterAttached(onAttached, onDetached)
  const browserCanvasRef = useRef<HTMLCanvasElement>(null)

  // Browser path: start after mount
  useEffect(() => {
    if (!isWebFEnvironment && browserCanvasRef.current) {
      startAnimation(browserCanvasRef.current)
    }
    return () => stopAnimation()
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [])

  const canvasRef = isWebFEnvironment ? flutterCanvasRef : browserCanvasRef

  return (
    <div className="w-full aspect-square max-h-[400px] flex items-center justify-center bg-white/70 dark:bg-slate-900/60 rounded-xl overflow-hidden">
      <canvas
        ref={canvasRef}
        style={{ width: '100%', height: '100%' }}
        className="w-full h-full"
      />
    </div>
  )
}

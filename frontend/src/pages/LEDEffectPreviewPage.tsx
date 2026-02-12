import { useCallback, useEffect, useMemo, useRef, useState } from 'react'
import { useNavigate, useLocation, useParams, WebFRouter } from '@openwebf/react-router'
import { FlutterCupertinoActionSheet } from '@openwebf/react-cupertino-ui'
import type { FlutterCupertinoActionSheetElement } from '@openwebf/react-cupertino-ui'
import DynamicComponentLoader from '../components/DynamicComponentLoader'
import DeviceCanvasView from '../components/DeviceCanvasView'
import type { DeviceConfig } from '../types/device'

interface LedEffectManifest {
  id: string
  name: string
  description: string
}

interface DeviceManifest {
  devices: string[]
}

function tryExtractInnerPathFromHybridUrl(maybeHybridUrl: string | undefined): string | undefined {
  if (!maybeHybridUrl) return undefined
  const qIndex = maybeHybridUrl.indexOf('?')
  if (qIndex < 0) return undefined
  const query = maybeHybridUrl.slice(qIndex + 1)
  if (!query) return undefined

  try {
    const searchParams = new URLSearchParams(query)
    const encodedPath = searchParams.get('path')
    if (!encodedPath) return undefined

    // `path` is usually percent-encoded (e.g. %2Fled%2Fwave)
    const decoded = decodeURIComponent(encodedPath)
    return decoded || undefined
  } catch {
    return undefined
  }
}

export default function LEDEffectPreviewPage() {
  const { navigate } = useNavigate()
  const params = useParams()
  const location = useLocation()

  const effectId = useMemo(() => {
    // Try params first
    const direct = (params as unknown as { effectId?: string }).effectId
    if (direct) return direct

    // Some WebF routing setups may expose the real path via a splat param or a `path` param.
    const splat = (params as unknown as Record<string, unknown>)['*']
    if (typeof splat === 'string' && splat) {
      const segments = splat.split('/').filter(Boolean)
      const last = segments[segments.length - 1]
      if (last) return last
    }

    const paramPath = (params as unknown as Record<string, unknown>)['path']
    if (typeof paramPath === 'string' && paramPath) {
      const segments = paramPath.split('/').filter(Boolean)
      const last = segments[segments.length - 1]
      if (last) return last
    }

    // WebF hybrid routing wraps the real route into query param `path`.
    // We try to extract the inner route from both WebFRouter.path and location.pathname.
    const webfRawPath = (WebFRouter as unknown as { path?: string } | undefined)?.path
    const locationPathname = String((location as unknown as { pathname?: string }).pathname ?? '')

    const innerFromWebf = tryExtractInnerPathFromHybridUrl(webfRawPath)
    const innerFromLocation = tryExtractInnerPathFromHybridUrl(locationPathname)

    const effectivePath = innerFromWebf || innerFromLocation || webfRawPath || locationPathname
    const segments = effectivePath.split('/').filter(Boolean)
    return segments[segments.length - 1] ?? ''
  }, [params, location])

  // ── effect source loading ───────────────────────────────────
  const [loading, setLoading] = useState(false)
  const [manifest, setManifest] = useState<LedEffectManifest | null>(null)
  const [effectCode, setEffectCode] = useState('')
  const [loadError, setLoadError] = useState<string | null>(null)

  // ── device state ────────────────────────────────────────────
  const [deviceList, setDeviceList] = useState<string[]>([])
  const [selectedDeviceId, setSelectedDeviceId] = useState<string | null>(null)
  const [deviceConfig, setDeviceConfig] = useState<DeviceConfig | null>(null)

  // LED buffer shared between dynamic effect code (writer) and canvas (reader)
  const ledBufferRef = useRef<Uint8Array | null>(null)
  const actionSheetRef = useRef<FlutterCupertinoActionSheetElement>(null)

  // ── fetch device manifest on mount ──────────────────────────
  useEffect(() => {
    const base = import.meta.env.BASE_URL
    let cancelled = false

    fetch(`${base}devices/manifest.json`)
      .then((res) => (res.ok ? res.json() : Promise.reject(new Error('Failed to load device manifest'))))
      .then((data: DeviceManifest) => {
        if (cancelled) return
        setDeviceList(data.devices)
        // Auto-select if only one device
        if (data.devices.length === 1) {
          setSelectedDeviceId(data.devices[0])
        }
      })
      .catch((e) => {
        console.warn('Could not load device manifest:', e)
      })

    return () => { cancelled = true }
  }, [])

  // ── fetch device config when selection changes ──────────────
  useEffect(() => {
    if (!selectedDeviceId) {
      setDeviceConfig(null)
      ledBufferRef.current = null
      return
    }

    const base = import.meta.env.BASE_URL
    let cancelled = false

    fetch(`${base}devices/${selectedDeviceId}/config.json`)
      .then((res) => (res.ok ? res.json() : Promise.reject(new Error(`Failed to load device config for "${selectedDeviceId}"`))))
      .then((config: DeviceConfig) => {
        if (cancelled) return
        setDeviceConfig(config)
        // Initialize LED buffer for total LED count across all strips
        const totalLeds = config.strips.reduce((sum, s) => sum + s.ledCount, 0)
        ledBufferRef.current = new Uint8Array(totalLeds * 3)
      })
      .catch((e) => {
        console.error('Failed to load device config:', e)
        if (!cancelled) {
          setDeviceConfig(null)
          ledBufferRef.current = null
        }
      })

    return () => { cancelled = true }
  }, [selectedDeviceId])

  // ── onTick callback: copy LED data into shared buffer ───────
  const handleTick = useCallback((leds: Uint8Array) => {
    if (ledBufferRef.current && ledBufferRef.current.length === leds.length) {
      ledBufferRef.current.set(leds)
    }
  }, [])

  // ── fetch effect source code ────────────────────────────────
  useEffect(() => {
    if (!effectId) return

    setLoading(true)
    setLoadError(null)
    setManifest(null)
    setEffectCode('')

    let cancelled = false

    const load = async () => {
      try {
        // Fetch effect-runtime, ui-hooks, meta.json, effect.js and ui.tsx in parallel
        const base = import.meta.env.BASE_URL
        const [metaRes, runtimeRes, uiHooksRes, effectRes, uiRes] = await Promise.all([
          fetch(`${base}effects/${effectId}/meta.json`),
          fetch(`${base}effects/effect-runtime.js`),
          fetch(`${base}effects/ui-hooks.tsx`),
          fetch(`${base}effects/${effectId}/effect.js`),
          fetch(`${base}effects/${effectId}/ui.tsx`),
        ])

        if (cancelled) return

        if (!metaRes.ok) throw new Error(`Failed to load meta.json for effect "${effectId}"`)
        const meta: { id?: string; name: string; description: string } = await metaRes.json()
        setManifest({ id: meta.id ?? effectId, name: meta.name, description: meta.description })

        if (!runtimeRes.ok) throw new Error('Failed to load effects/effect-runtime.js')
        if (!uiHooksRes.ok) throw new Error('Failed to load effects/ui-hooks.tsx')
        if (!effectRes.ok) throw new Error(`Failed to load effect.js for "${effectId}"`)
        if (!uiRes.ok) throw new Error(`Failed to load ui.tsx for "${effectId}"`)

        const runtimeCode = await runtimeRes.text()
        const uiHooksCode = await uiHooksRes.text()
        const effectCode = await effectRes.text()
        const uiCode = await uiRes.text()

        // Combine: effect-runtime → effect logic → ui-hooks → UI component
        if (!cancelled) setEffectCode(`${runtimeCode}\n\n${effectCode}\n\n${uiHooksCode}\n\n${uiCode}`)
      } catch (e) {
        console.error('Failed to load effect:', e)
        if (!cancelled) setLoadError(e instanceof Error ? e.message : String(e))
      } finally {
        if (!cancelled) setLoading(false)
      }
    }

    void load()
    return () => { cancelled = true }
  }, [effectId])

  // ── componentProps passed to dynamic effect code ────────────
  const componentProps = useMemo(() => {
    if (!deviceConfig) return undefined
    return {
      deviceConfig,
      onTick: handleTick,
    }
  }, [deviceConfig, handleTick])

  // Force re-mount DynamicComponentLoader when device changes (ledCount changes)
  const loaderKey = `${effectId}-${selectedDeviceId ?? 'none'}`

  return (
    <div className="min-h-screen bg-slate-50 px-5 py-5 text-slate-900 dark:bg-slate-950 dark:text-slate-100">
      <div className="max-w-4xl mx-auto">
        {/* Header */}
        <div className="flex items-center justify-between gap-4 mb-4">
          <div className="flex-1 min-w-0 text-slate-900 dark:text-slate-100">
            <h1 className="text-2xl sm:text-3xl font-bold leading-tight drop-shadow truncate">
              {manifest?.name ?? effectId ?? 'Unknown Effect'}
            </h1>
            {manifest?.description ? (
              <p className="text-sm sm:text-base opacity-70 text-slate-600 dark:text-slate-400">{manifest.description}</p>
            ) : null}
          </div>

          {/* Device selector via native ActionSheet */}
          {deviceList.length > 0 && (
            <>
              <FlutterCupertinoActionSheet
                ref={actionSheetRef}
                onSelect={(e: CustomEvent<{ event: string }>) => {
                  const ev = e.detail.event
                  setSelectedDeviceId(ev === 'none' ? null : ev)
                }}
              />
              <button
                onClick={() => {
                  actionSheetRef.current?.show({
                    title: 'Select Device',
                    actions: [
                      { text: 'No Device', event: 'none' },
                      ...deviceList.map((id) => ({
                        text: id,
                        event: id,
                        isDefault: id === selectedDeviceId,
                      })),
                    ],
                    cancelButton: { text: 'Cancel', event: 'cancel' },
                  })
                }}
                className="shrink-0 rounded-lg border border-slate-300 bg-white px-3 py-2 text-sm font-medium text-slate-900 transition active:scale-[0.97] dark:border-slate-700 dark:bg-slate-800 dark:text-slate-100"
              >
                {selectedDeviceId ?? 'No Device'}
              </button>
            </>
          )}

          <button
            className="shrink-0 rounded-full border border-slate-300 bg-white/70 px-4 py-2 text-sm font-semibold text-slate-900 transition hover:opacity-95 active:scale-[0.98] dark:border-slate-700 dark:bg-slate-900/60 dark:text-slate-100"
            onClick={() => navigate(-1)}
          >
            Back
          </button>
        </div>

        {/* Canvas visualization */}
        {deviceConfig && (
          <div className="mb-4 rounded-2xl border border-slate-200 bg-white shadow-lg overflow-hidden dark:border-slate-800 dark:bg-slate-900/60">
            <DeviceCanvasView deviceConfig={deviceConfig} ledBufferRef={ledBufferRef} />
          </div>
        )}

        {/* Effect controls (dynamic TSX) */}
        <div className="rounded-2xl border border-slate-200 bg-white shadow-xl min-h-[300px] dark:border-slate-800 dark:bg-slate-900/60">
          {loading ? (
            <div className="text-center py-16 text-slate-600 dark:text-slate-400">
              <div className="inline-block w-12 h-12 rounded-full border-4 border-slate-300 border-t-sky-500 animate-spin dark:border-slate-700 dark:border-t-sky-400" />
              <p className="mt-5 text-base">Loading effect...</p>
            </div>
          ) : loadError ? (
            <div className="p-5 bg-red-900/20 border-2 border-red-500/50 rounded-lg text-red-200 m-4">
              <h3 className="text-lg font-bold mb-2">Failed to load effect source</h3>
              <div className="text-center text-slate-600 dark:text-slate-400 p-8">
                <p className="font-semibold">Effect not found.</p>
                <p className="mt-1 text-sm text-slate-600 dark:text-slate-400">
                  Looking for ID:{' '}
                  <code className="rounded border border-slate-300 bg-white/70 px-1 py-0.5 text-xs text-yellow-500 dark:border-slate-700 dark:bg-slate-900/60">{String(effectId)}</code>
                </p>
              </div>
              <p className="font-mono text-sm whitespace-pre-wrap break-words">{loadError}</p>
            </div>
          ) : effectCode ? (
            <DynamicComponentLoader
              key={loaderKey}
              code={effectCode}
              componentName={effectId}
              componentProps={componentProps}
            />
          ) : (
            <div className="text-center text-slate-600 dark:text-slate-400 p-8">
              <p className="font-semibold">Select an effect to preview</p>
            </div>
          )}
        </div>
      </div>
    </div>
  )
}

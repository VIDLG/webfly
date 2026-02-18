import { useCallback, useEffect, useMemo, useRef, useState } from 'react'
import { useNavigate, useLocation, useParams, WebFRouter } from '@openwebf/react-router'
import { FlutterCupertinoActionSheet } from '@openwebf/react-cupertino-ui'
import type { FlutterCupertinoActionSheetElement } from '@openwebf/react-cupertino-ui'
import { useQuery } from '@tanstack/react-query'
import type { Spec } from '@json-render/core'
import EffectRenderer, { type EffectBridgeConfig, type SpeedConfig } from '../effects/EffectRenderer'
import DeviceCanvasView from '../components/DeviceCanvasView'
import type { LedEffectManifest } from '../types/effect'
import type { DeviceConfig } from '../types/device'

interface EffectLoadResult {
  manifest: LedEffectManifest
  uiSpec: Spec
  effectLogicCode: string
  bridgeConfig?: EffectBridgeConfig
  speedConfig?: SpeedConfig
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

// ── query functions ─────────────────────────────────────────

async function fetchDeviceList(): Promise<string[]> {
  const base = import.meta.env.BASE_URL
  const res = await fetch(`${base}devices/manifest.json`)
  if (!res.ok) throw new Error('Failed to load device manifest')
  const data: { devices: string[] } = await res.json()
  return data.devices
}

async function fetchDeviceConfig(deviceId: string): Promise<DeviceConfig> {
  const base = import.meta.env.BASE_URL
  const res = await fetch(`${base}devices/${deviceId}/config.json`)
  if (!res.ok) throw new Error(`Failed to load device config for "${deviceId}"`)
  return res.json()
}

async function fetchEffectSource(
  effectId: string,
  onStep: (msg: string) => void,
): Promise<EffectLoadResult> {
  onStep('Downloading scripts...')
  const base = import.meta.env.BASE_URL

  const [metaRes, uiJsonRes, runtimeRes, effectRes] = await Promise.all([
    fetch(`${base}effects/${effectId}/meta.json`),
    fetch(`${base}effects/${effectId}/ui.json`),
    fetch(`${base}effects/effect-runtime.ts`),
    fetch(`${base}effects/${effectId}/effect.ts`),
  ])

  if (!metaRes.ok) throw new Error(`Failed to load meta.json for effect "${effectId}"`)
  if (!uiJsonRes.ok) throw new Error(`Failed to load ui.json for "${effectId}"`)
  if (!runtimeRes.ok) throw new Error('Failed to load effects/effect-runtime.ts')
  if (!effectRes.ok) throw new Error(`Failed to load effect.ts for "${effectId}"`)

  onStep('Parsing sources...')
  const [meta, uiJson, runtimeCode, effectCode] = await Promise.all([
    metaRes.json() as Promise<{ id?: string; name: string; description: string }>,
    uiJsonRes.json() as Promise<Spec & { bridge?: EffectBridgeConfig; speed?: SpeedConfig }>,
    runtimeRes.text(),
    effectRes.text(),
  ])

  const manifest: LedEffectManifest = { id: meta.id ?? effectId, name: meta.name, description: meta.description }

  // Extract optional bridge/speed config from ui.json (not json-render fields)
  const bridgeConfig = uiJson.bridge
  const speedConfig = uiJson.speed
  const uiSpec: Spec = { root: uiJson.root, elements: uiJson.elements, state: uiJson.state }

  // Concatenate runtime + effect for Babel compilation (pure TS, no JSX)
  const effectLogicCode = `${runtimeCode}\n\n${effectCode}`

  onStep('Ready')
  return { manifest, uiSpec, effectLogicCode, bridgeConfig, speedConfig }
}

// ── component ───────────────────────────────────────────────

export default function LEDEffectPreviewPage() {
  const { navigate } = useNavigate()
  const params = useParams()
  const location = useLocation()

  const effectId = useMemo(() => {
    // Strip query string from a path segment using URL parser
    const stripQuery = (s: string) => new URL(s, 'http://x').pathname.split('/').pop() ?? s

    // Try params first
    const direct = (params as unknown as { effectId?: string }).effectId
    if (direct) return stripQuery(direct)

    // Some WebF routing setups may expose the real path via a splat param or a `path` param.
    const splat = (params as unknown as Record<string, unknown>)['*']
    if (typeof splat === 'string' && splat) {
      const segments = splat.split('/').filter(Boolean)
      const last = segments[segments.length - 1]
      if (last) return stripQuery(last)
    }

    const paramPath = (params as unknown as Record<string, unknown>)['path']
    if (typeof paramPath === 'string' && paramPath) {
      const segments = paramPath.split('/').filter(Boolean)
      const last = segments[segments.length - 1]
      if (last) return stripQuery(last)
    }

    // WebF hybrid routing wraps the real route into query param `path`.
    // We try to extract the inner route from both WebFRouter.path and location.pathname.
    const webfRawPath = (WebFRouter as unknown as { path?: string } | undefined)?.path
    const locationPathname = String((location as unknown as { pathname?: string }).pathname ?? '')

    const innerFromWebf = tryExtractInnerPathFromHybridUrl(webfRawPath)
    const innerFromLocation = tryExtractInnerPathFromHybridUrl(locationPathname)

    const effectivePath = innerFromWebf || innerFromLocation || webfRawPath || locationPathname
    const segments = effectivePath.split('/').filter(Boolean)
    return stripQuery(segments[segments.length - 1] ?? '')
  }, [params, location])

  // ── loading step progress ─────────────────────────────────
  const [loadingStep, setLoadingStep] = useState('')
  const [elapsedMs, setElapsedMs] = useState(0)
  const stepRef = useRef(setLoadingStep)
  stepRef.current = setLoadingStep

  // ── device state ──────────────────────────────────────────
  const [selectedDeviceId, setSelectedDeviceId] = useState<string | null>(null)
  const ledBufferRef = useRef<Uint8Array | null>(null)
  const actionSheetRef = useRef<FlutterCupertinoActionSheetElement>(null)

  // ── queries ───────────────────────────────────────────────
  const { data: deviceList = [] } = useQuery({
    queryKey: ['devices', 'list'],
    queryFn: fetchDeviceList,
  })

  // Auto-select the only device
  useEffect(() => {
    if (deviceList.length === 1 && !selectedDeviceId) {
      setSelectedDeviceId(deviceList[0])
    }
  }, [deviceList, selectedDeviceId])

  const { data: deviceConfig = null } = useQuery({
    queryKey: ['devices', 'config', selectedDeviceId],
    queryFn: () => fetchDeviceConfig(selectedDeviceId!),
    enabled: !!selectedDeviceId,
  })

  // Initialize LED buffer when device config changes
  useEffect(() => {
    if (!deviceConfig) {
      ledBufferRef.current = null
      return
    }
    const totalLeds = deviceConfig.strips.reduce((sum, s) => sum + s.ledCount, 0)
    ledBufferRef.current = new Uint8Array(totalLeds * 3)
  }, [deviceConfig])

  const effectQuery = useQuery({
    queryKey: ['effects', effectId, 'source'],
    queryFn: () => fetchEffectSource(effectId, (msg) => stepRef.current(msg)),
    enabled: !!effectId,
  })

  const loading = effectQuery.isLoading || effectQuery.isFetching
  const loadError = effectQuery.error
  const effectData = effectQuery.data ?? null
  const manifest = effectData?.manifest ?? null

  // Elapsed timer — ticks every 100ms while loading
  useEffect(() => {
    if (!loading) return
    setElapsedMs(0)
    const t0 = Date.now()
    const id = window.setInterval(() => setElapsedMs(Date.now() - t0), 100)
    return () => clearInterval(id)
  }, [loading])

  // ── onTick callback: copy LED data into shared buffer ───────
  const handleTick = useCallback((leds: Uint8Array) => {
    if (ledBufferRef.current && ledBufferRef.current.length === leds.length) {
      ledBufferRef.current.set(leds)
    }
  }, [])

  // Force re-mount EffectRenderer when device changes (ledCount changes)
  const loaderKey = `${effectId}-${selectedDeviceId ?? 'none'}`

  return (
    <div className="min-h-screen bg-slate-50 px-5 py-5 text-slate-900 dark:bg-slate-950 dark:text-slate-100">
      <div className="max-w-4xl mx-auto">
        {/* Header row: Back (left) | Title (centered) | Device (right) */}
        <div className="relative flex items-center justify-center min-h-[44px] mb-1">
          <button
            className="absolute left-0 shrink-0 rounded-full border border-slate-300 bg-white/70 px-4 py-2 text-sm font-semibold text-slate-900 transition hover:opacity-95 active:scale-[0.98] dark:border-slate-700 dark:bg-slate-900/60 dark:text-slate-100"
            onClick={() => navigate(-1)}
          >
            Back
          </button>

          <h1 className="text-2xl sm:text-3xl font-bold leading-tight drop-shadow truncate text-center text-slate-900 dark:text-slate-100 px-20">
            {manifest?.name ?? effectId ?? 'Unknown Effect'}
          </h1>

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
                className="absolute right-0 shrink-0 rounded-lg border border-slate-300 bg-white px-3 py-2 text-sm font-medium text-slate-900 transition active:scale-[0.97] dark:border-slate-700 dark:bg-slate-800 dark:text-slate-100"
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
              >
                {selectedDeviceId ?? 'No Device'}
              </button>
            </>
          )}
        </div>

        {/* Description row */}
        {manifest?.description ? (
          <p className="text-sm sm:text-base text-slate-600 dark:text-slate-400 mb-4">{manifest.description}</p>
        ) : <div className="mb-4" />}

        {/* Canvas visualization */}
        {deviceConfig && (
          <div className="mb-4 rounded-2xl border border-slate-200 bg-white shadow-lg overflow-hidden dark:border-slate-800 dark:bg-slate-900/60">
            <DeviceCanvasView deviceConfig={deviceConfig} ledBufferRef={ledBufferRef} />
          </div>
        )}

        {/* Effect controls */}
        <div className="rounded-2xl border border-slate-200 bg-white shadow-xl min-h-[300px] dark:border-slate-800 dark:bg-slate-900/60">
          {loading ? (
            <div className="text-center py-16 text-slate-600 dark:text-slate-400">
              <div className="inline-block w-12 h-12 rounded-full border-4 border-slate-300 border-t-sky-500 animate-spin dark:border-slate-700 dark:border-t-sky-400" />
              <p className="mt-5 text-base">{loadingStep || 'Loading effect...'}</p>
              <p className="mt-1 text-xs tabular-nums text-slate-400 dark:text-slate-500">{(elapsedMs / 1000).toFixed(1)}s</p>
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
              <p className="font-mono text-sm whitespace-pre-wrap break-words">{loadError instanceof Error ? loadError.message : String(loadError)}</p>
            </div>
          ) : effectData ? (
            <EffectRenderer
              key={loaderKey}
              uiSpec={effectData.uiSpec}
              effectLogicCode={effectData.effectLogicCode}
              deviceConfig={deviceConfig}
              onTick={handleTick}
              bridgeConfig={effectData.bridgeConfig}
              speedConfig={effectData.speedConfig}
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

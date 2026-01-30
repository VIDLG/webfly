import { useEffect, useMemo, useState } from 'react'
import { useNavigate, useLocation, useParams, WebFRouter } from '@openwebf/react-router'
import { getEffectManifest, type LedEffectManifest } from '../led/effectsRegistry'
import DynamicComponentLoader from '../components/DynamicComponentLoader'

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

  const [loading, setLoading] = useState(false)
  const [manifest, setManifest] = useState<LedEffectManifest | null>(null)
  const [effectCode, setEffectCode] = useState('')
  const [loadError, setLoadError] = useState<string | null>(null)

  useEffect(() => {
    if (!effectId) return

    setLoading(true)
    setLoadError(null)
    setManifest(null)
    setEffectCode('')

    const load = async () => {
      try {
        // 1. Get Manifest
        const m = getEffectManifest(effectId)
        if (!m) {
          throw new Error(`Effect "${effectId}" not found in registry.`)
        }
        setManifest(m)

        // 2. Fetch Code (Logic + UI)
        const [logicRes, uiRes] = await Promise.all([
          fetch(`/effects/${effectId}/logic.ts`),
          fetch(`/effects/${effectId}/ui.tsx`),
        ])

        if (!logicRes.ok) throw new Error(`Failed to load logic.ts for ${effectId}`)
        if (!uiRes.ok) throw new Error(`Failed to load ui.tsx for ${effectId}`)

        const logicCode = await logicRes.text()
        const uiCode = await uiRes.text()

        // Combine logic and UI
        // We prepend logic so the hook is available in scope for the component
        setEffectCode(`${logicCode}\n\n${uiCode}`)
      } catch (e) {
        console.error('Failed to load effect:', e)
        setLoadError(e instanceof Error ? e.message : String(e))
      } finally {
        setLoading(false)
      }
    }

    void load()
  }, [effectId])

  return (
    <div className="min-h-screen bg-slate-950 py-5 px-5">
      <div className="max-w-4xl mx-auto">
        <div className="flex items-center justify-between gap-4 mb-4">
          <div className="text-white">
            <h1 className="text-2xl sm:text-3xl font-bold leading-tight drop-shadow">
              {manifest?.name ?? effectId ?? 'Unknown Effect'}
            </h1>
            {manifest?.description ? (
              <p className="text-sm sm:text-base opacity-70 text-gray-300">{manifest.description}</p>
            ) : null}
          </div>

          <button
            className="shrink-0 rounded-full bg-slate-800 border border-slate-700 px-4 py-2 text-sm font-semibold text-white transition hover:bg-slate-700 active:scale-[0.98]"
            onClick={() => navigate(-1)}
          >
            ← Back
          </button>
        </div>

        <div className="bg-slate-900 rounded-2xl ring-1 ring-slate-800 shadow-xl min-h-[500px]">
          {loading ? (
            <div className="text-center py-16 text-gray-400">
              <div className="inline-block w-12 h-12 border-4 border-slate-700 border-t-indigo-500 rounded-full animate-spin" />
              <p className="mt-5 text-base">Loading effect...</p>
            </div>
          ) : loadError ? (
            <div className="p-5 bg-red-900/20 border-2 border-red-500/50 rounded-lg text-red-200 m-4">
              <h3 className="text-lg font-bold mb-2">❌ Failed to load effect source</h3>
              <div className="text-center text-gray-400 p-8">
                <p className="font-semibold">Effect not found.</p>
                <p className="mt-1 text-sm text-gray-500">
                  Looking for ID:{' '}
                  <code className="bg-slate-800 px-1 py-0.5 rounded text-xs text-yellow-500">{String(effectId)}</code>
                </p>
              </div>
              <p className="font-mono text-sm whitespace-pre-wrap break-words">{loadError}</p>
            </div>
          ) : effectCode ? (
            <DynamicComponentLoader code={effectCode} componentName={effectId} />
          ) : (
            <div className="text-center text-gray-400 p-8">
              <p className="font-semibold">Select an effect to preview</p>
            </div>
          )}
        </div>
      </div>
    </div>
  )
}

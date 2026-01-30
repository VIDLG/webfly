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
    <div className="min-h-screen bg-slate-50 px-5 py-5 text-slate-900 dark:bg-slate-950 dark:text-slate-100">
      <div className="max-w-4xl mx-auto">
        <div className="flex items-center justify-between gap-4 mb-4">
          <div className="text-slate-900 dark:text-slate-100">
            <h1 className="text-2xl sm:text-3xl font-bold leading-tight drop-shadow">
              {manifest?.name ?? effectId ?? 'Unknown Effect'}
            </h1>
            {manifest?.description ? (
              <p className="text-sm sm:text-base opacity-70 text-slate-600 dark:text-slate-400">{manifest.description}</p>
            ) : null}
          </div>

          <button
            className="shrink-0 rounded-full border border-slate-300 bg-white/70 px-4 py-2 text-sm font-semibold text-slate-900 transition hover:opacity-95 active:scale-[0.98] dark:border-slate-700 dark:bg-slate-900/60 dark:text-slate-100"
            onClick={() => navigate(-1)}
          >
            ← Back
          </button>
        </div>

        <div className="rounded-2xl border border-slate-200 bg-white shadow-xl min-h-[500px] dark:border-slate-800 dark:bg-slate-900/60">
          {loading ? (
            <div className="text-center py-16 text-slate-600 dark:text-slate-400">
              <div className="inline-block w-12 h-12 rounded-full border-4 border-slate-300 border-t-sky-500 animate-spin dark:border-slate-700 dark:border-t-sky-400" />
              <p className="mt-5 text-base">Loading effect...</p>
            </div>
          ) : loadError ? (
            <div className="p-5 bg-red-900/20 border-2 border-red-500/50 rounded-lg text-red-200 m-4">
              <h3 className="text-lg font-bold mb-2">❌ Failed to load effect source</h3>
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
            <DynamicComponentLoader code={effectCode} componentName={effectId} />
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

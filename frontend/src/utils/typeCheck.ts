/**
 * Browser-side TypeScript type checking via external API.
 *
 * Uses the free ts-check.okikio.dev TwoSlash API to run full TypeScript
 * diagnostics on dynamically-generated effect code.
 *
 * If the API is unreachable (offline, timeout, etc.), type checking is
 * silently skipped and the code proceeds to Babel compilation.
 */

const API_URL = 'https://ts-check.okikio.dev/twoslash'
const API_TIMEOUT_MS = 15_000

/** Simple in-memory cache keyed by code+extension. Skipped results are not cached. */
const cache = new Map<string, TypeCheckResult>()

export function clearTypeCheckCache() {
  cache.clear()
}

export interface TypeDiagnostic {
  line: number
  column: number
  message: string
  category: 'error' | 'warning'
}

export interface TypeCheckTiming {
  totalMs: number
  /** Server processing time from Server-Timing header, if available. */
  serverMs?: number
  cached: boolean
}

export interface TypeCheckResult {
  success: boolean
  diagnostics: TypeDiagnostic[]
  skipped?: boolean
  timing: TypeCheckTiming
}

/**
 * Run TypeScript type checking on dynamically-generated code via external API.
 *
 * @param code          Source code to check (the full concatenated effect code)
 * @param extension     File extension hint ('ts' | 'tsx')
 * @returns             Result with success flag and diagnostics, or skipped=true if API unavailable
 */
export async function typeCheckCode(
  code: string,
  extension: string = 'tsx',
): Promise<TypeCheckResult> {
  const cacheKey = `${extension}\0${code}`
  const cached = cache.get(cacheKey)
  if (cached) return { ...cached, timing: { ...cached.timing, cached: true } }

  const t0 = performance.now()

  try {
    const controller = new AbortController()
    const timeout = setTimeout(() => controller.abort(), API_TIMEOUT_MS)

    const formData = new FormData()
    formData.append('code', code)
    formData.append('extension', extension)

    const res = await fetch(API_URL, {
      method: 'POST',
      body: formData,
      signal: controller.signal,
    })
    clearTimeout(timeout)

    if (!res.ok) {
      console.warn(`[typeCheck] API returned ${res.status}, skipping type check`)
      return { success: true, diagnostics: [], skipped: true, timing: { totalMs: performance.now() - t0, cached: false } }
    }

    // Try to extract server processing time from Server-Timing header
    // Format: "total;dur=1234" or "cpu;dur=567"
    let serverMs: number | undefined
    const serverTiming = res.headers.get('Server-Timing') ?? res.headers.get('X-Response-Time')
    if (serverTiming) {
      const durMatch = serverTiming.match(/dur[ation]*[=:](\d+(?:\.\d+)?)/)
      if (durMatch) serverMs = parseFloat(durMatch[1])
    }

    const data = await res.json()

    // TwoSlash response shape: { errors: [{ renderedMessage, line, character, category, ... }] }
    const errors: Array<{
      renderedMessage: string
      line: number
      character: number
      category: number // 0=Warning, 1=Error, 2=Suggestion, 3=Message
    }> = data.errors ?? []

    const diagnostics: TypeDiagnostic[] = errors
      .filter((e) => e.category <= 1) // only warnings and errors
      .map((e) => ({
        line: (e.line ?? 0) + 1,
        column: (e.character ?? 0) + 1,
        message: e.renderedMessage ?? 'Unknown error',
        category: e.category === 1 ? ('error' as const) : ('warning' as const),
      }))

    const totalMs = performance.now() - t0
    const timing: TypeCheckTiming = { totalMs, serverMs, cached: false }

    const result: TypeCheckResult = {
      success: diagnostics.filter((d) => d.category === 'error').length === 0,
      diagnostics,
      timing,
    }
    cache.set(cacheKey, result)
    return result
  } catch (e) {
    // Network error, timeout, or abort — silently skip type checking
    const reason = e instanceof DOMException && e.name === 'AbortError' ? 'timeout' : 'network error'
    console.warn(`[typeCheck] API unreachable (${reason}), skipping type check`)
    return { success: true, diagnostics: [], skipped: true, timing: { totalMs: performance.now() - t0, cached: false } }
  }
}

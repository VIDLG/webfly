import { describe, it, expect, vi, beforeEach } from 'vitest'
import { typeCheckCode, clearTypeCheckCache } from '../typeCheck'

/** Helper: create a mock fetch Response with JSON body and optional headers. */
function mockResponse(
  body: unknown,
  ok = true,
  status = 200,
  headers?: Record<string, string>,
): Response {
  return {
    ok,
    status,
    json: () => Promise.resolve(body),
    headers: new Headers(headers),
  } as Response
}

beforeEach(() => {
  vi.restoreAllMocks()
  clearTypeCheckCache()
})

describe('typeCheckCode', () => {
  it('returns success when API reports no errors', async () => {
    vi.spyOn(globalThis, 'fetch').mockResolvedValue(
      mockResponse({ errors: [] }),
    )

    const result = await typeCheckCode('const x: number = 42')
    expect(result.success).toBe(true)
    expect(result.diagnostics).toHaveLength(0)
    expect(result.timing).toBeDefined()
    expect(result.timing.cached).toBe(false)
    expect(result.timing.totalMs).toBeGreaterThanOrEqual(0)
  })

  it('returns diagnostics when API reports type errors', async () => {
    vi.spyOn(globalThis, 'fetch').mockResolvedValue(
      mockResponse({
        errors: [
          {
            renderedMessage: "Type 'string' is not assignable to type 'number'.",
            line: 0,
            character: 18,
            category: 1, // Error
          },
        ],
      }),
    )

    const result = await typeCheckCode('const x: number = "hello"')
    expect(result.success).toBe(false)
    expect(result.diagnostics).toHaveLength(1)
    expect(result.diagnostics[0].category).toBe('error')
    expect(result.diagnostics[0].message).toContain('not assignable')
    expect(result.diagnostics[0].line).toBe(1)
    expect(result.diagnostics[0].column).toBe(19)
  })

  it('filters out suggestions (category > 1)', async () => {
    vi.spyOn(globalThis, 'fetch').mockResolvedValue(
      mockResponse({
        errors: [
          { renderedMessage: 'A suggestion', line: 0, character: 0, category: 2 },
          { renderedMessage: 'A message', line: 0, character: 0, category: 3 },
        ],
      }),
    )

    const result = await typeCheckCode('const x = 1')
    expect(result.success).toBe(true)
    expect(result.diagnostics).toHaveLength(0)
  })

  it('treats warnings (category 0) as non-blocking', async () => {
    vi.spyOn(globalThis, 'fetch').mockResolvedValue(
      mockResponse({
        errors: [
          { renderedMessage: 'A warning', line: 2, character: 5, category: 0 },
        ],
      }),
    )

    const result = await typeCheckCode('const x = 1')
    expect(result.success).toBe(true)
    expect(result.diagnostics).toHaveLength(1)
    expect(result.diagnostics[0].category).toBe('warning')
  })

  it('skips gracefully when API returns non-OK status', async () => {
    vi.spyOn(globalThis, 'fetch').mockResolvedValue(
      mockResponse({}, false, 500),
    )

    const result = await typeCheckCode('const x = 1')
    expect(result.success).toBe(true)
    expect(result.skipped).toBe(true)
    expect(result.diagnostics).toHaveLength(0)
  })

  it('skips gracefully on network error', async () => {
    vi.spyOn(globalThis, 'fetch').mockRejectedValue(new TypeError('Failed to fetch'))

    const result = await typeCheckCode('const x = 1')
    expect(result.success).toBe(true)
    expect(result.skipped).toBe(true)
    expect(result.diagnostics).toHaveLength(0)
  })

  it('skips gracefully on timeout (AbortError)', async () => {
    vi.spyOn(globalThis, 'fetch').mockRejectedValue(
      new DOMException('The operation was aborted', 'AbortError'),
    )

    const result = await typeCheckCode('const x = 1')
    expect(result.success).toBe(true)
    expect(result.skipped).toBe(true)
  })

  it('sends code and extension via FormData POST', async () => {
    const fetchSpy = vi.spyOn(globalThis, 'fetch').mockResolvedValue(
      mockResponse({ errors: [] }),
    )

    await typeCheckCode('const x = 1', 'ts')

    expect(fetchSpy).toHaveBeenCalledOnce()
    const [url, init] = fetchSpy.mock.calls[0]
    expect(url).toBe('https://ts-check.okikio.dev/twoslash')
    expect(init?.method).toBe('POST')

    const body = init?.body as FormData
    expect(body.get('code')).toBe('const x = 1')
    expect(body.get('extension')).toBe('ts')
  })

  it('returns cached result on second call with same code', async () => {
    const fetchSpy = vi.spyOn(globalThis, 'fetch').mockResolvedValue(
      mockResponse({ errors: [] }),
    )

    const first = await typeCheckCode('const cached = true')
    expect(first.timing.cached).toBe(false)

    const second = await typeCheckCode('const cached = true')

    expect(fetchSpy).toHaveBeenCalledOnce()
    expect(second.success).toBe(first.success)
    expect(second.diagnostics).toEqual(first.diagnostics)
    expect(second.timing.cached).toBe(true)
  })

  it('does not cache skipped results (network error)', async () => {
    const fetchSpy = vi.spyOn(globalThis, 'fetch')
    fetchSpy.mockRejectedValueOnce(new TypeError('Failed to fetch'))
    fetchSpy.mockResolvedValueOnce(mockResponse({ errors: [] }))

    const first = await typeCheckCode('const retry = 1')
    expect(first.skipped).toBe(true)

    const second = await typeCheckCode('const retry = 1')
    expect(second.skipped).toBeUndefined()
    expect(fetchSpy).toHaveBeenCalledTimes(2)
  })

  it('handles empty errors array', async () => {
    vi.spyOn(globalThis, 'fetch').mockResolvedValue(
      mockResponse({ errors: [] }),
    )

    const result = await typeCheckCode('')
    expect(result.success).toBe(true)
    expect(result.diagnostics).toHaveLength(0)
  })

  it('parses Server-Timing header for serverMs', async () => {
    vi.spyOn(globalThis, 'fetch').mockResolvedValue(
      mockResponse({ errors: [] }, true, 200, { 'Server-Timing': 'total;dur=1234' }),
    )

    const result = await typeCheckCode('const st = 1')
    expect(result.timing.serverMs).toBe(1234)
    expect(result.timing.cached).toBe(false)
  })

  it('parses X-Response-Time header as fallback', async () => {
    vi.spyOn(globalThis, 'fetch').mockResolvedValue(
      mockResponse({ errors: [] }, true, 200, { 'X-Response-Time': 'duration=567.5' }),
    )

    const result = await typeCheckCode('const xrt = 1')
    expect(result.timing.serverMs).toBe(567.5)
  })

  it('leaves serverMs undefined when no timing header present', async () => {
    vi.spyOn(globalThis, 'fetch').mockResolvedValue(
      mockResponse({ errors: [] }),
    )

    const result = await typeCheckCode('const noth = 1')
    expect(result.timing.serverMs).toBeUndefined()
  })

  it('includes timing even on skipped results', async () => {
    vi.spyOn(globalThis, 'fetch').mockRejectedValue(new TypeError('Failed to fetch'))

    const result = await typeCheckCode('const skip = 1')
    expect(result.skipped).toBe(true)
    expect(result.timing).toBeDefined()
    expect(result.timing.totalMs).toBeGreaterThanOrEqual(0)
    expect(result.timing.cached).toBe(false)
  })
})

#!/usr/bin/env node
/**
 * Benchmark the TwoSlash type-check API latency.
 *
 * Usage:
 *   node scripts/bench-typecheck-api.mjs            # 5 rounds, default snippet
 *   node scripts/bench-typecheck-api.mjs -n 10      # 10 rounds
 *   node scripts/bench-typecheck-api.mjs -f code.ts  # use file as payload
 */

const API_URL = 'https://ts-check.okikio.dev/twoslash'

const DEFAULT_CODE = `
interface TaggedColor { tag: string; r: number; g: number; b: number }
function hsvToRgb(h: number, s: number, v: number): TaggedColor {
  const i = Math.floor(h * 6)
  const f = h * 6 - i
  const p = v * (1 - s)
  const q = v * (1 - f * s)
  const t = v * (1 - (1 - f) * s)
  const mod = i % 6
  const r = [v, q, p, p, t, v][mod] * 255
  const g = [t, v, v, q, p, p][mod] * 255
  const b = [p, p, t, v, v, q][mod] * 255
  return { tag: 'hsv', r: Math.round(r), g: Math.round(g), b: Math.round(b) }
}
const c: TaggedColor = hsvToRgb(0.5, 1, 1)
console.log(c.r, c.g, c.b)
`.trim()

// ── arg parsing ──────────────────────────────────────────────
import { readFileSync } from 'node:fs'

let rounds = 5
let code = DEFAULT_CODE

const args = process.argv.slice(2)
for (let i = 0; i < args.length; i++) {
  if ((args[i] === '-n' || args[i] === '--rounds') && args[i + 1]) {
    rounds = parseInt(args[++i], 10)
  } else if ((args[i] === '-f' || args[i] === '--file') && args[i + 1]) {
    code = readFileSync(args[++i], 'utf-8')
  } else if (args[i] === '-h' || args[i] === '--help') {
    console.log('Usage: bench-typecheck-api.mjs [-n rounds] [-f file.ts]')
    process.exit(0)
  }
}

// ── benchmark ────────────────────────────────────────────────

async function ping() {
  const form = new FormData()
  form.append('code', code)
  form.append('extension', 'tsx')

  const t0 = performance.now()
  const res = await fetch(API_URL, { method: 'POST', body: form })
  const bodyMs = performance.now()

  // TwoSlash returns 400 when code has undeclared type errors — still a valid response
  let data
  try { data = await res.json() } catch { data = null }
  const elapsed = performance.now() - t0
  const networkMs = bodyMs - t0

  if (!data) return { ok: false, status: res.status, ms: elapsed, networkMs }

  const errors = (data.errors ?? []).filter((e) => e.category <= 1)
  return { ok: true, status: res.status, ms: elapsed, networkMs, errors: errors.length }
}

console.log(`API:     ${API_URL}`)
console.log(`Code:    ${code.length} chars, ${code.split('\n').length} lines`)
console.log(`Rounds:  ${rounds}`)
console.log()

const results = []
for (let i = 0; i < rounds; i++) {
  const label = `  [${i + 1}/${rounds}]`
  try {
    const r = await ping()
    results.push(r)
    const errInfo = r.errors != null ? `, ${r.errors} type error(s)` : ''
    const net = r.networkMs != null ? ` (TTFB ${r.networkMs.toFixed(0)} ms)` : ''
    console.log(`${label}  ${r.ms.toFixed(0).padStart(6)} ms${net}  HTTP ${r.status}${errInfo}`)
  } catch (e) {
    console.log(`${label}  FAILED  ${e.message}`)
    results.push({ ok: false, ms: NaN })
  }
}

// ── summary ──────────────────────────────────────────────────
const valid = results.filter((r) => !isNaN(r.ms))
if (valid.length === 0) {
  console.log('\nAll requests failed.')
  process.exit(1)
}

const times = valid.map((r) => r.ms).sort((a, b) => a - b)
const sum = times.reduce((a, b) => a + b, 0)
const avg = sum / times.length
const min = times[0]
const max = times[times.length - 1]
const median = times.length % 2 === 1
  ? times[Math.floor(times.length / 2)]
  : (times[times.length / 2 - 1] + times[times.length / 2]) / 2
const p95 = times[Math.min(Math.floor(times.length * 0.95), times.length - 1)]

const ttfbs = valid.filter((r) => r.networkMs != null).map((r) => r.networkMs).sort((a, b) => a - b)
const ttfbAvg = ttfbs.length ? ttfbs.reduce((a, b) => a + b, 0) / ttfbs.length : NaN

console.log()
console.log('Summary (total round-trip):')
console.log(`  min     ${min.toFixed(0)} ms`)
console.log(`  max     ${max.toFixed(0)} ms`)
console.log(`  avg     ${avg.toFixed(0)} ms`)
console.log(`  median  ${median.toFixed(0)} ms`)
console.log(`  p95     ${p95.toFixed(0)} ms`)
if (ttfbs.length) {
  console.log()
  console.log('TTFB (time to first byte, ~ server processing + network latency):')
  console.log(`  min     ${ttfbs[0].toFixed(0)} ms`)
  console.log(`  max     ${ttfbs[ttfbs.length - 1].toFixed(0)} ms`)
  console.log(`  avg     ${ttfbAvg.toFixed(0)} ms`)
}
console.log()
console.log(`  ok      ${valid.filter((r) => r.ok).length}/${rounds}`)

#!/usr/bin/env node
/**
 * Compile LED effects into self-contained plain JS files for mquickjs.
 *
 * Each output file bundles effect-runtime + the effect's own logic so it
 * can run standalone on a microcontroller without any module system.
 *
 * Usage: node scripts/compile-effects.mjs [--outdir <dir>]
 *   Default outdir: public/effects/<id>/effect.js (next to the .ts source)
 */
import { readFileSync, writeFileSync, mkdirSync, existsSync } from 'node:fs'
import { execFileSync } from 'node:child_process'
import { dirname, join, resolve } from 'node:path'
import { fileURLToPath } from 'node:url'

const __dirname = dirname(fileURLToPath(import.meta.url))
const ROOT = resolve(__dirname, '..')
const EFFECTS_DIR = join(ROOT, 'public', 'effects')

// Locate the esbuild binary (works with pnpm hoisting)
const esbuildBin = join(ROOT, 'node_modules', '.bin', 'esbuild')
if (!existsSync(esbuildBin) && !existsSync(esbuildBin + '.cmd')) {
  console.error('esbuild not found. Run: cd frontend && pnpm install')
  process.exit(1)
}

// Parse --outdir flag (optional, default writes next to source)
let outdir = null
const args = process.argv.slice(2)
for (let i = 0; i < args.length; i++) {
  if (args[i] === '--outdir' && args[i + 1]) {
    outdir = resolve(args[i + 1])
  }
}

function stripTypes(code) {
  // Use esbuild CLI via stdin to strip TypeScript types.
  // On Windows, .bin shims are shell scripts so we need to invoke via sh.
  const bin = process.platform === 'win32' ? 'sh' : esbuildBin
  const esbuildArgs = ['--loader=ts', '--target=es2020']
  const spawnArgs = process.platform === 'win32'
    ? [esbuildBin, ...esbuildArgs]
    : esbuildArgs
  return execFileSync(bin, spawnArgs, { input: code, encoding: 'utf8' })
}

// 1. Read & strip the shared runtime
const runtimeTs = readFileSync(join(EFFECTS_DIR, 'effect-runtime.ts'), 'utf8')
const runtimeJs = stripTypes(runtimeTs)

// 2. Read manifest
const manifest = JSON.parse(
  readFileSync(join(EFFECTS_DIR, 'manifest.json'), 'utf8'),
)

const header = [
  '// Auto-generated – do not edit. Run: just compile-effects',
  '// Target: mquickjs (ES2020, no modules)',
  '',
].join('\n')

let count = 0
for (const id of manifest.effects) {
  const effectTs = readFileSync(join(EFFECTS_DIR, id, 'effect.ts'), 'utf8')
  const effectJs = stripTypes(effectTs)

  const combined = [
    header,
    '// ── effect-runtime ──',
    runtimeJs.trimEnd(),
    '',
    `// ── effect: ${id} ──`,
    effectJs.trimEnd(),
    '',
  ].join('\n')

  const dest = outdir
    ? join(outdir, `${id}.js`)
    : join(EFFECTS_DIR, id, 'effect.js')
  mkdirSync(dirname(dest), { recursive: true })
  writeFileSync(dest, combined, 'utf8')
  count++
  console.log(`  ${id} → ${dest}`)
}

console.log(`\nCompiled ${count} effect(s).`)

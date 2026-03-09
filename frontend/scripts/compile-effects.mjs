#!/usr/bin/env node
/**
 * Compile LED effects into self-contained plain JS files for mquickjs.
 *
 * Each output file bundles effect-runtime + the effect's own logic so it
 * can run standalone on a microcontroller without any module system.
 *
 * Usage: node scripts/compile-effects.mjs [--target es5|es2015|es2020|...] [--outdir <dir>]
 *   --target: JS language level (default: es5)
 *   --outdir: output directory (default: next to each effect.ts)
 */
import { readFileSync, writeFileSync, mkdirSync } from 'node:fs'
import { dirname, join, resolve } from 'node:path'
import { fileURLToPath } from 'node:url'
import { createRequire } from 'node:module'

const require = createRequire(import.meta.url)
const ts = require('typescript')

const __dirname = dirname(fileURLToPath(import.meta.url))
const ROOT = resolve(__dirname, '..')
const EFFECTS_DIR = join(ROOT, 'public', 'effects')

// Parse CLI flags
var outdir = null
var target = 'es6'
var args = process.argv.slice(2)
for (var i = 0; i < args.length; i++) {
  if (args[i] === '--outdir' && args[i + 1]) {
    outdir = resolve(args[++i])
  } else if (args[i] === '--target' && args[i + 1]) {
    target = args[++i].toLowerCase()
  }
}

// Map target string to TypeScript ScriptTarget enum
var TARGET_MAP = {
  es5: ts.ScriptTarget.ES5,
  es2015: ts.ScriptTarget.ES2015, es6: ts.ScriptTarget.ES2015,
  es2016: ts.ScriptTarget.ES2016,
  es2017: ts.ScriptTarget.ES2017,
  es2018: ts.ScriptTarget.ES2018,
  es2019: ts.ScriptTarget.ES2019,
  es2020: ts.ScriptTarget.ES2020,
  es2021: ts.ScriptTarget.ES2021,
  es2022: ts.ScriptTarget.ES2022,
  esnext: ts.ScriptTarget.ESNext,
}
var scriptTarget = TARGET_MAP[target]
if (scriptTarget === undefined) {
  console.error('Unknown target: ' + target + '. Valid: ' + Object.keys(TARGET_MAP).join(', '))
  process.exit(1)
}

function transpile(code) {
  var result = ts.transpileModule(code, {
    compilerOptions: {
      target: scriptTarget,
      module: ts.ModuleKind.None,
      removeComments: false,
    },
  })
  return result.outputText
}

// 1. Read & transpile the shared runtime
var runtimeTs = readFileSync(join(EFFECTS_DIR, 'effect-runtime.ts'), 'utf8')
var runtimeJs = transpile(runtimeTs)

// 2. Read manifest
var manifest = JSON.parse(
  readFileSync(join(EFFECTS_DIR, 'manifest.json'), 'utf8'),
)

var header = [
  '// Auto-generated – do not edit. Run: just compile-effects',
  '// Target: mquickjs (' + target.toUpperCase() + ', no modules)',
  '',
].join('\n')

var count = 0
for (var idx = 0; idx < manifest.effects.length; idx++) {
  var id = manifest.effects[idx]
  var effectTs = readFileSync(join(EFFECTS_DIR, id, 'effect.ts'), 'utf8')
  var effectJs = transpile(effectTs)

  var combined = [
    header,
    '// ── effect-runtime ──',
    runtimeJs.trimEnd(),
    '',
    '// ── effect: ' + id + ' ──',
    effectJs.trimEnd(),
    '',
  ].join('\n')

  var dest = outdir
    ? join(outdir, id + '.js')
    : join(EFFECTS_DIR, id, 'effect.js')
  mkdirSync(dirname(dest), { recursive: true })
  writeFileSync(dest, combined, 'utf8')
  count++
  console.log('  ' + id + ' -> ' + dest)
}

console.log('\nCompiled ' + count + ' effect(s).')

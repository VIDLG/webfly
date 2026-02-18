/**
 * DynamicRenderer — generic runtime component renderer.
 *
 * Supports two modes:
 *   - **TSX**: compiles source code via Babel at runtime, extracts the default
 *     export as a React component, and renders it with the given props.
 *   - **JSON**: renders a json-render `Spec` using a caller-provided registry.
 *
 * This component knows nothing about LED effects, machines, or bridges.
 * Domain-specific wrappers (e.g. EffectRenderer) can layer their own
 * Context / state management on top.
 */

import React, { useEffect, useState } from 'react'
import * as ReactNamespace from 'react'
import * as Babel from '@babel/standalone'
import { Renderer, JSONUIProvider } from '@json-render/react'
import type { Spec } from '@json-render/core'
import type { ComponentRegistry } from '@json-render/react'

// ── Babel types ──────────────────────────────────────────────

type BabelOptions = {
  filename?: string
  presets?: (string | [string, Record<string, unknown>])[]
  plugins?: string[]
  sourceType?: 'module' | 'script' | 'unambiguous'
}

type BabelStandaloneApi = {
  transform: (code: string, options: BabelOptions) => { code?: string | null }
  disableScriptTags?: () => void
}

function getBabelApi(): BabelStandaloneApi {
  const api = Babel as unknown as BabelStandaloneApi
  api.disableScriptTags?.()
  return api
}

// ── Shared UI fragments ──────────────────────────────────────

function LoadingSpinner({ message }: { message: string }) {
  return (
    <div className="p-5 text-center text-slate-600 dark:text-slate-400">
      <div className="inline-block h-10 w-10 rounded-full border-4 border-slate-300 border-t-sky-500 animate-spin dark:border-slate-700 dark:border-t-sky-400" />
      <p className="mt-2.5">{message}</p>
    </div>
  )
}

function ErrorBlock({ title, message }: { title: string; message: string }) {
  return (
    <div className="p-5 bg-red-900/20 border-2 border-red-500/50 rounded-lg text-red-200">
      <h3 className="text-lg font-bold mb-2">{title}</h3>
      <p className="font-mono text-sm whitespace-pre-wrap break-words">{message}</p>
    </div>
  )
}

// ── TSX mode ─────────────────────────────────────────────────

/**
 * Compiles TSX source code via Babel at runtime and returns a React component.
 *
 * @param globals - key/value pairs injected as named parameters into the
 *   compiled function scope. The caller decides what's available (e.g.
 *   CupertinoComponents, useTheme, etc.).
 */
function useTsxComponent(
  code: string,
  filename: string,
  globals: Record<string, unknown>,
) {
  // eslint-disable-next-line @typescript-eslint/no-explicit-any
  const [Component, setComponent] = useState<React.ComponentType<any> | null>(null)
  const [error, setError] = useState<string | null>(null)

  useEffect(() => {
    let cancelled = false

    try {
      setError(null)
      setComponent(null)

      // Some sandbox code may reference the global `React`
      ;(window as unknown as { React: typeof ReactNamespace }).React = ReactNamespace

      const babelApi = getBabelApi()
      const result = babelApi.transform(code, {
        filename: `${filename}.tsx`,
        presets: [['react', { runtime: 'classic' }], 'typescript'],
        plugins: ['transform-modules-commonjs'],
        sourceType: 'module',
      })

      const compiled = result.code
      if (!compiled) throw new Error('Compiled code is empty')

      // eslint-disable-next-line @typescript-eslint/no-explicit-any
      const exportsObj: any = {}
      // eslint-disable-next-line @typescript-eslint/no-explicit-any
      const moduleObj: any = { exports: exportsObj }

      // Build parameter list: React + exports + module + caller-provided globals
      const globalNames = Object.keys(globals)
      const globalValues = Object.values(globals)

      const fn = new Function(
        'React', 'exports', 'module', ...globalNames,
        `${compiled}\nreturn module.exports?.default ?? exports.default;`,
      )
      const loaded = fn(ReactNamespace, exportsObj, moduleObj, ...globalValues)

      if (!loaded) throw new Error('Could not extract component from code (ensure there is a default export)')
      if (!cancelled) setComponent(() => loaded)
    } catch (e) {
      console.error('Failed to load dynamic component:', e)
      if (!cancelled) setError(e instanceof Error ? e.message : String(e))
    }

    return () => { cancelled = true }
  }, [code, filename]) // globals is expected to be stable (caller uses useMemo)

  return { Component, error }
}

interface TsxModeProps {
  mode: 'tsx'
  /** Source code to compile (concatenated runtime + hooks + component) */
  code: string
  /** Identifier used as Babel filename */
  filename: string
  /** Globals to inject into the compiled function scope */
  globals?: Record<string, unknown>
  /** Props to pass to the compiled component */
  componentProps?: Record<string, unknown>
}

function TsxRenderer({ code, filename, globals, componentProps }: TsxModeProps) {
  const { Component, error } = useTsxComponent(code, filename, globals ?? {})

  if (error) return <ErrorBlock title="Component Loading Failed" message={error} />
  if (!Component) return <LoadingSpinner message="Compiling component..." />

  return (
    <div className="w-full h-full">
      <Component {...(componentProps ?? {})} />
    </div>
  )
}

// ── JSON mode ────────────────────────────────────────────────

interface JsonModeProps {
  mode: 'json'
  /** json-render UI spec */
  spec: Spec
  /** json-render component registry */
  registry: ComponentRegistry
  /** Initial state for JSONUIProvider */
  initialState?: Record<string, unknown>
  /** Called when json-render state changes */
  onStateChange?: (path: string, value: unknown) => void
  /** Optional wrapper around the Renderer (e.g. to inject Context providers) */
  children?: (renderer: React.ReactNode) => React.ReactNode
}

function JsonRenderer({ spec, registry, initialState, onStateChange, children }: JsonModeProps) {
  const rendererNode = <Renderer spec={spec} registry={registry} />

  return (
    <JSONUIProvider
      registry={registry}
      initialState={initialState}
      onStateChange={onStateChange}
    >
      {children ? children(rendererNode) : rendererNode}
    </JSONUIProvider>
  )
}

// ── Public API ───────────────────────────────────────────────

export type DynamicRendererProps = TsxModeProps | JsonModeProps

/**
 * Generic runtime renderer that dispatches to TSX or JSON mode.
 *
 * - **TSX mode**: Babel-compiles source code, renders the exported React component.
 * - **JSON mode**: Renders a json-render Spec with the provided registry.
 */
export default function DynamicRenderer(props: DynamicRendererProps) {
  if (props.mode === 'tsx') {
    return <TsxRenderer {...props} />
  }
  return <JsonRenderer {...props} />
}

// Re-export types for convenience
export type { TsxModeProps, JsonModeProps, BabelStandaloneApi, BabelOptions }
// Re-export Babel helper for use in higher-level wrappers (e.g. compiling effect logic)
export { getBabelApi }

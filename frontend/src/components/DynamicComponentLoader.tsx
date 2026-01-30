import React, { useEffect, useState } from 'react'
import * as ReactNamespace from 'react'
import * as CupertinoComponents from '@openwebf/react-cupertino-ui'
import * as Babel from '@babel/standalone'

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

interface DynamicComponentLoaderProps {
  code: string
  componentName: string
}

/**
 * Dynamic Component Loader
 * - Loads TSX from source string
 * - Compiles at runtime using @babel/standalone
 * - Transforms ESModule export to CommonJS, then executes with new Function
 */
export default function DynamicComponentLoader({ code, componentName }: DynamicComponentLoaderProps) {
  const [Component, setComponent] = useState<React.ComponentType | null>(null)
  const [error, setError] = useState<string | null>(null)

  useEffect(() => {
    let cancelled = false

    const compileAndLoad = async () => {
      try {
        setError(null)
        setComponent(null)

        ;(window as unknown as { React: typeof ReactNamespace }).React = ReactNamespace

        const babelApi = Babel as unknown as BabelStandaloneApi

        // In WebF environment, Babel/standalone might try to scan <script type="text/babel">; explicitly disable this
        babelApi.disableScriptTags?.()

        const result = babelApi.transform(code, {
          filename: `${componentName}.tsx`,
          // IMPORTANT:
          // - runtime: 'classic' avoids injecting "react/jsx-runtime" import (new Function cannot execute import)
          presets: [['react', { runtime: 'classic' }], 'typescript'],
          // Convert `export default` to `exports.default = ...`
          plugins: ['transform-modules-commonjs'],
          sourceType: 'module',
        })

        const compiled = result.code
        if (!compiled) throw new Error('Compiled code is empty')

        // Mock CommonJS environment
        // eslint-disable-next-line @typescript-eslint/no-explicit-any
        const exportsObj: any = {}
        // eslint-disable-next-line @typescript-eslint/no-explicit-any
        const moduleObj: any = { exports: exportsObj }

        const fn = new Function('React', 'exports', 'module', 'CupertinoComponents', `${compiled}\nreturn module.exports?.default ?? exports.default;`)
        const loaded = fn(ReactNamespace, exportsObj, moduleObj, CupertinoComponents)

        if (!loaded) throw new Error('Could not extract component from code (ensure there is a default export)')
        if (!cancelled) setComponent(() => loaded)
      } catch (e) {
        console.error('Failed to load dynamic component:', e)
        if (!cancelled) setError(e instanceof Error ? e.message : String(e))
      }
    }

    compileAndLoad()
    return () => {
      cancelled = true
    }
  }, [code, componentName])

  if (error) {
    return (
      <div className="p-5 bg-red-900/20 border-2 border-red-500/50 rounded-lg text-red-200">
        <h3 className="text-lg font-bold mb-2">❌ Component Loading Failed</h3>
        <p className="font-mono text-sm whitespace-pre-wrap break-words">{error}</p>
      </div>
    )
  }

  if (!Component) {
    return (
      <div className="p-5 text-center text-gray-400">
        <div className="inline-block w-10 h-10 border-4 border-slate-700 border-t-indigo-500 rounded-full animate-spin" />
        <p className="mt-2.5">Compiling/Loading component...</p>
      </div>
    )
  }

  return (
    <div className="w-full h-full">
      <Component />
    </div>
  )
}

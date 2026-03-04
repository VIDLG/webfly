import { useState, useMemo } from 'react'
import { useNavigate } from '@openwebf/react-router'

/* ── Types ── */

type TestStatus = 'pass' | 'fail' | 'partial' | 'skip'

interface TestResult {
  name: string
  status: TestStatus
  detail?: string
}

interface TestCategory {
  title: string
  tests: TestResult[]
}

/* ── Helpers ── */

function safeTest(fn: () => boolean, detail?: string): { status: TestStatus; detail?: string } {
  try {
    return { status: fn() ? 'pass' : 'fail', detail }
  } catch (e) {
    return { status: 'fail', detail: `${detail ?? ''} (${String(e)})`.trim() }
  }
}

/** Mark as known unsupported per WebF docs (no runtime check needed). */
function knownFail(detail?: string): { status: TestStatus; detail?: string } {
  return { status: 'fail', detail: detail ? `[Known] ${detail}` : '[Known]' }
}

/* ── Compatibility Tests ── */

function runAllTests(): TestCategory[] {
  const categories: TestCategory[] = []

  /* ─── Timers & Animation ─── */
  categories.push({
    title: 'Timers & Animation',
    tests: [
      { name: 'setTimeout', ...safeTest(() => typeof setTimeout === 'function') },
      { name: 'clearTimeout', ...safeTest(() => typeof clearTimeout === 'function') },
      { name: 'setInterval', ...safeTest(() => typeof setInterval === 'function') },
      { name: 'clearInterval', ...safeTest(() => typeof clearInterval === 'function') },
      { name: 'requestAnimationFrame', ...safeTest(() => typeof requestAnimationFrame === 'function') },
      { name: 'cancelAnimationFrame', ...safeTest(() => typeof cancelAnimationFrame === 'function') },
    ],
  })

  /* ─── Storage ─── */
  categories.push({
    title: 'Storage',
    tests: [
      { name: 'localStorage', ...safeTest(() => typeof localStorage !== 'undefined' && typeof localStorage.getItem === 'function') },
      { name: 'sessionStorage', ...safeTest(() => typeof sessionStorage !== 'undefined' && typeof sessionStorage.getItem === 'function') },
      { name: 'IndexedDB', ...safeTest(() => typeof indexedDB !== 'undefined', 'Not supported in WebF — use native plugin') },
    ],
  })

  /* ─── Networking ─── */
  categories.push({
    title: 'Networking',
    tests: [
      { name: 'fetch', ...safeTest(() => typeof fetch === 'function') },
      { name: 'XMLHttpRequest', ...safeTest(() => typeof XMLHttpRequest === 'function') },
      { name: 'WebSocket', ...safeTest(() => typeof WebSocket === 'function') },
      { name: 'URL', ...safeTest(() => typeof URL === 'function') },
      { name: 'URLSearchParams', ...safeTest(() => typeof URLSearchParams === 'function') },
    ],
  })

  /* ─── DOM Core ─── */
  categories.push({
    title: 'DOM Core',
    tests: [
      { name: 'document', ...safeTest(() => typeof document !== 'undefined') },
      { name: 'window', ...safeTest(() => typeof window !== 'undefined') },
      { name: 'navigator', ...safeTest(() => typeof navigator !== 'undefined') },
      { name: 'querySelector', ...safeTest(() => typeof document.querySelector === 'function') },
      { name: 'querySelectorAll', ...safeTest(() => typeof document.querySelectorAll === 'function') },
      { name: 'getElementById', ...safeTest(() => typeof document.getElementById === 'function') },
      { name: 'getElementsByClassName', ...safeTest(() => typeof document.getElementsByClassName === 'function') },
      { name: 'getElementsByTagName', ...safeTest(() => typeof document.getElementsByTagName === 'function') },
      { name: 'createElement', ...safeTest(() => typeof document.createElement === 'function') },
      { name: 'createTextNode', ...safeTest(() => typeof document.createTextNode === 'function') },
    ],
  })

  /* ─── DOM Manipulation ─── */
  categories.push({
    title: 'DOM Manipulation',
    tests: [
      {
        name: 'appendChild',
        ...safeTest(() => {
          const el = document.createElement('div')
          return typeof el.appendChild === 'function'
        }),
      },
      {
        name: 'removeChild',
        ...safeTest(() => {
          const el = document.createElement('div')
          return typeof el.removeChild === 'function'
        }),
      },
      {
        name: 'insertBefore',
        ...safeTest(() => {
          const el = document.createElement('div')
          return typeof el.insertBefore === 'function'
        }),
      },
      {
        name: 'cloneNode',
        ...safeTest(() => {
          const el = document.createElement('div')
          return typeof el.cloneNode === 'function'
        }),
      },
      {
        name: 'compareDocumentPosition',
        ...safeTest(() => {
          const el = document.createElement('div')
          return typeof el.compareDocumentPosition === 'function'
        }, 'Used by Base UI CompositeList'),
      },
      {
        name: 'Node.isConnected',
        ...safeTest(() => {
          const el = document.createElement('div')
          return 'isConnected' in el
        }),
      },
      {
        name: 'Node.DOCUMENT_POSITION_*',
        ...safeTest(() => {
          return typeof Node !== 'undefined' && typeof Node.DOCUMENT_POSITION_FOLLOWING === 'number'
        }),
      },
      {
        name: 'Shadow DOM (attachShadow)',
        ...safeTest(() => {
          const el = document.createElement('div')
          return typeof el.attachShadow === 'function'
        }, 'Not supported — use framework components'),
      },
      {
        name: 'Custom Elements',
        ...safeTest(() => typeof customElements !== 'undefined' && typeof customElements.define === 'function'),
      },
    ],
  })

  /* ─── Event System ─── */
  categories.push({
    title: 'Event System',
    tests: [
      {
        name: 'addEventListener',
        ...safeTest(() => {
          const el = document.createElement('div')
          return typeof el.addEventListener === 'function'
        }),
      },
      {
        name: 'removeEventListener',
        ...safeTest(() => {
          const el = document.createElement('div')
          return typeof el.removeEventListener === 'function'
        }),
      },
      {
        name: 'dispatchEvent',
        ...safeTest(() => {
          const el = document.createElement('div')
          return typeof el.dispatchEvent === 'function'
        }),
      },
      {
        name: 'new Event()',
        ...safeTest(() => {
          const evt = new Event('test')
          return evt instanceof Event
        }),
      },
      {
        name: 'new CustomEvent()',
        ...safeTest(() => {
          const evt = new CustomEvent('test', { detail: 1 })
          return evt instanceof CustomEvent && evt.detail === 1
        }),
      },
      {
        name: 'new PointerEvent()',
        ...safeTest(() => {
          const evt = new PointerEvent('click', { bubbles: true })
          return evt instanceof PointerEvent
        }, 'Used by Base UI Switch/Checkbox'),
      },
      {
        name: 'new MouseEvent()',
        ...safeTest(() => {
          const evt = new MouseEvent('click', { bubbles: true })
          return evt instanceof MouseEvent
        }),
      },
      {
        name: 'new KeyboardEvent()',
        ...safeTest(() => {
          const evt = new KeyboardEvent('keydown', { key: 'Enter' })
          return evt instanceof KeyboardEvent
        }),
      },
      {
        name: 'new InputEvent()',
        ...safeTest(() => {
          const evt = new InputEvent('input', { data: 'a' })
          return evt instanceof InputEvent
        }),
      },
    ],
  })

  /* ─── Observers ─── */
  categories.push({
    title: 'Observers',
    tests: [
      { name: 'MutationObserver', ...safeTest(() => typeof MutationObserver === 'function') },
      { name: 'IntersectionObserver', ...safeTest(() => typeof IntersectionObserver === 'function', 'Use onscreen/offscreen events') },
      { name: 'ResizeObserver', ...safeTest(() => typeof ResizeObserver === 'function') },
      { name: 'PerformanceObserver', ...safeTest(() => typeof PerformanceObserver === 'function') },
    ],
  })

  /* ─── Global Objects ─── */
  categories.push({
    title: 'Global Objects',
    tests: [
      { name: 'Intl', ...safeTest(() => typeof Intl !== 'undefined', 'Used by Base UI Progress') },
      { name: 'Intl.NumberFormat', ...safeTest(() => typeof Intl !== 'undefined' && typeof Intl.NumberFormat === 'function') },
      { name: 'Intl.DateTimeFormat', ...safeTest(() => typeof Intl !== 'undefined' && typeof Intl.DateTimeFormat === 'function') },
      { name: 'JSON', ...safeTest(() => typeof JSON !== 'undefined' && typeof JSON.parse === 'function') },
      { name: 'Promise', ...safeTest(() => typeof Promise === 'function') },
      { name: 'Map', ...safeTest(() => typeof Map === 'function') },
      { name: 'Set', ...safeTest(() => typeof Set === 'function') },
      { name: 'WeakMap', ...safeTest(() => typeof WeakMap === 'function') },
      { name: 'WeakSet', ...safeTest(() => typeof WeakSet === 'function') },
      { name: 'Symbol', ...safeTest(() => typeof Symbol === 'function') },
      { name: 'Proxy', ...safeTest(() => typeof Proxy === 'function') },
      { name: 'Reflect', ...safeTest(() => typeof Reflect !== 'undefined') },
      { name: 'AbortController', ...safeTest(() => typeof AbortController === 'function') },
      { name: 'TextEncoder', ...safeTest(() => typeof TextEncoder === 'function') },
      { name: 'TextDecoder', ...safeTest(() => typeof TextDecoder === 'function') },
      { name: 'crypto', ...safeTest(() => typeof crypto !== 'undefined') },
      { name: 'crypto.subtle', ...safeTest(() => typeof crypto !== 'undefined' && typeof crypto.subtle !== 'undefined') },
      { name: 'performance.now', ...safeTest(() => typeof performance !== 'undefined' && typeof performance.now === 'function') },
    ],
  })

  /* ─── Graphics ─── */
  categories.push({
    title: 'Graphics',
    tests: [
      {
        name: 'Canvas 2D',
        ...safeTest(() => {
          const c = document.createElement('canvas')
          return !!(c.getContext && c.getContext('2d'))
        }),
      },
      {
        name: 'WebGL',
        ...safeTest(() => {
          const c = document.createElement('canvas')
          return !!(c.getContext && c.getContext('webgl'))
        }, 'Not available in WebF'),
      },
      {
        name: 'WebGL2',
        ...safeTest(() => {
          const c = document.createElement('canvas')
          return !!(c.getContext && c.getContext('webgl2'))
        }, 'Not available in WebF'),
      },
      {
        name: 'OffscreenCanvas',
        ...safeTest(() => typeof OffscreenCanvas === 'function'),
      },
    ],
  })

  /* ─── Workers & Threads ─── */
  categories.push({
    title: 'Workers & Threads',
    tests: [
      { name: 'Web Worker', ...safeTest(() => typeof Worker === 'function', 'Not needed — JS runs on dedicated thread') },
      { name: 'Service Worker', ...safeTest(() => 'serviceWorker' in navigator, 'Not supported') },
      { name: 'Shared Worker', ...safeTest(() => typeof SharedWorker === 'function', 'Not supported') },
    ],
  })

  /* ─── Animation APIs ─── */
  categories.push({
    title: 'Animation APIs',
    tests: [
      {
        name: 'Web Animations API (el.animate)',
        ...safeTest(() => {
          const el = document.createElement('div')
          return typeof el.animate === 'function'
        }, 'Use CSS animations instead'),
      },
      {
        name: 'getComputedStyle',
        ...safeTest(() => typeof getComputedStyle === 'function'),
      },
    ],
  })

  /* ─── CSS Feature Detection ─── */
  const hasSupports = typeof CSS !== 'undefined' && typeof CSS.supports === 'function'

  // Fallback: set style on a temp element and check if it sticks
  const cssCheck = (prop: string, val: string): boolean => {
    if (hasSupports) return CSS.supports(prop, val)
    try {
      const el = document.createElement('div')
      const s: CSSStyleDeclaration = el.style
      s.setProperty(prop, val)
      return s.getPropertyValue(prop) !== ''
    } catch {
      return false
    }
  }

  categories.push({
    title: 'CSS API',
    tests: [
      { name: 'CSS.supports()', ...safeTest(() => hasSupports) },
      { name: 'getComputedStyle', ...safeTest(() => typeof getComputedStyle === 'function') },
      { name: 'el.style (inline)', ...safeTest(() => 'style' in document.createElement('div')) },
    ],
  })

  /* ─── CSS Layout Modes ─── */
  categories.push({
    title: 'CSS Layout',
    tests: [
      { name: 'display: block', ...safeTest(() => cssCheck('display', 'block')) },
      { name: 'display: inline', ...safeTest(() => cssCheck('display', 'inline')) },
      { name: 'display: inline-block', ...safeTest(() => cssCheck('display', 'inline-block')) },
      { name: 'display: flex', ...safeTest(() => cssCheck('display', 'flex')) },
      { name: 'display: inline-flex', ...safeTest(() => cssCheck('display', 'inline-flex')) },
      { name: 'display: grid', ...knownFail('Coming soon — use flexbox') },
      { name: 'display: table', ...knownFail('Use flexbox instead') },
      { name: 'float: left', ...knownFail('Use flexbox instead') },
      { name: 'float: right', ...knownFail('Use flexbox instead') },
    ],
  })

  /* ─── CSS Positioning ─── */
  categories.push({
    title: 'CSS Positioning',
    tests: [
      { name: 'position: relative', ...safeTest(() => cssCheck('position', 'relative')) },
      { name: 'position: absolute', ...safeTest(() => cssCheck('position', 'absolute')) },
      { name: 'position: fixed', ...safeTest(() => cssCheck('position', 'fixed')) },
      { name: 'position: sticky', ...safeTest(() => cssCheck('position', 'sticky')) },
      { name: 'z-index', ...safeTest(() => cssCheck('z-index', '1')) },
    ],
  })

  /* ─── CSS Flexbox ─── */
  categories.push({
    title: 'CSS Flexbox',
    tests: [
      { name: 'flex-direction', ...safeTest(() => cssCheck('flex-direction', 'column')) },
      { name: 'justify-content', ...safeTest(() => cssCheck('justify-content', 'center')) },
      { name: 'align-items', ...safeTest(() => cssCheck('align-items', 'center')) },
      { name: 'flex-wrap', ...safeTest(() => cssCheck('flex-wrap', 'wrap')) },
      { name: 'flex-grow', ...safeTest(() => cssCheck('flex-grow', '1')) },
      { name: 'flex-shrink', ...safeTest(() => cssCheck('flex-shrink', '0')) },
      { name: 'flex-basis', ...safeTest(() => cssCheck('flex-basis', 'auto')) },
      { name: 'gap', ...safeTest(() => cssCheck('gap', '1px')) },
      { name: 'align-self', ...safeTest(() => cssCheck('align-self', 'center')) },
      { name: 'order', ...safeTest(() => cssCheck('order', '1')) },
    ],
  })

  /* ─── CSS Box Model ─── */
  categories.push({
    title: 'CSS Box Model & Sizing',
    tests: [
      { name: 'box-sizing', ...safeTest(() => cssCheck('box-sizing', 'border-box')) },
      { name: 'width / height', ...safeTest(() => cssCheck('width', '100px')) },
      { name: 'min-width / max-width', ...safeTest(() => cssCheck('min-width', '0px') && cssCheck('max-width', '100px')) },
      { name: 'margin', ...safeTest(() => cssCheck('margin', '0px')) },
      { name: 'padding', ...safeTest(() => cssCheck('padding', '0px')) },
      { name: 'overflow: hidden', ...safeTest(() => cssCheck('overflow', 'hidden')) },
      { name: 'overflow: auto', ...safeTest(() => cssCheck('overflow', 'auto')) },
    ],
  })

  /* ─── CSS Visual ─── */
  categories.push({
    title: 'CSS Visual',
    tests: [
      { name: 'border-radius', ...safeTest(() => cssCheck('border-radius', '8px')) },
      { name: 'box-shadow', ...safeTest(() => cssCheck('box-shadow', '0 0 0 1px black')) },
      { name: 'text-shadow', ...safeTest(() => cssCheck('text-shadow', '0 0 1px black')) },
      { name: 'opacity', ...safeTest(() => cssCheck('opacity', '0.5')) },
      { name: 'background-image (gradient)', ...safeTest(() => cssCheck('background-image', 'linear-gradient(red,blue)')) },
      { name: 'filter: blur()', ...safeTest(() => cssCheck('filter', 'blur(4px)')) },
      { name: 'backdrop-filter', ...knownFail('Not supported in WebF') },
      { name: 'clip-path', ...safeTest(() => cssCheck('clip-path', 'circle(50%)')) },
    ],
  })

  /* ─── CSS Transforms & Animations ─── */
  categories.push({
    title: 'CSS Transforms & Animations',
    tests: [
      { name: 'transform: translate()', ...safeTest(() => cssCheck('transform', 'translate(0,0)')) },
      { name: 'transform: rotate()', ...safeTest(() => cssCheck('transform', 'rotate(45deg)')) },
      { name: 'transform: scale()', ...safeTest(() => cssCheck('transform', 'scale(1)')) },
      { name: 'transform: skew()', ...safeTest(() => cssCheck('transform', 'skew(10deg)')) },
      { name: 'transform-origin', ...safeTest(() => cssCheck('transform-origin', 'center')) },
      { name: 'perspective', ...safeTest(() => cssCheck('perspective', '500px')) },
      { name: 'transition', ...safeTest(() => cssCheck('transition', 'all 0.3s')) },
      { name: 'animation', ...safeTest(() => cssCheck('animation', 'none')) },
    ],
  })

  /* ─── CSS Units ─── */
  categories.push({
    title: 'CSS Units',
    tests: [
      { name: 'px', ...safeTest(() => cssCheck('width', '1px')) },
      { name: 'em', ...safeTest(() => cssCheck('width', '1em')) },
      { name: 'rem', ...safeTest(() => cssCheck('width', '1rem')) },
      { name: '%', ...safeTest(() => cssCheck('width', '50%')) },
      { name: 'vw / vh', ...safeTest(() => cssCheck('width', '1vw') && cssCheck('height', '1vh')) },
      { name: 'vmin / vmax', ...safeTest(() => cssCheck('width', '1vmin') && cssCheck('width', '1vmax')) },
      { name: 'dvh', ...knownFail('Advanced viewport unit') },
      { name: 'lvh', ...knownFail('Advanced viewport unit') },
      { name: 'svh', ...knownFail('Advanced viewport unit') },
      { name: 'calc()', ...safeTest(() => cssCheck('width', 'calc(100% - 20px)')) },
    ],
  })

  /* ─── CSS Advanced ─── */
  categories.push({
    title: 'CSS Advanced',
    tests: [
      { name: 'CSS Variables (var())', ...safeTest(() => cssCheck('color', 'var(--test)')) },
      { name: '@media queries', ...safeTest(() => typeof matchMedia === 'function') },
      { name: 'data-* attribute selectors', ...safeTest(() => {
        // Test if data attribute selectors work by applying style
        const el = document.createElement('div')
        el.setAttribute('data-test', 'true')
        el.style.cssText = 'display:none'
        document.body.appendChild(el)
        const style = document.createElement('style')
        style.textContent = '[data-test="true"] { color: rgb(1, 2, 3); }'
        document.head.appendChild(style)
        const computed = getComputedStyle(el).color
        document.body.removeChild(el)
        document.head.removeChild(style)
        return computed === 'rgb(1, 2, 3)'
      }, 'Used by Base UI data-[pressed] etc.') },
    ],
  })

  /* ─── Form & Input ─── */
  categories.push({
    title: 'Form & Input',
    tests: [
      {
        name: 'FormData',
        ...safeTest(() => typeof FormData === 'function'),
      },
      {
        name: 'input.validity',
        ...safeTest(() => {
          const input = document.createElement('input')
          return 'validity' in input
        }),
      },
      {
        name: 'input.checkValidity()',
        ...safeTest(() => {
          const input = document.createElement('input')
          return typeof input.checkValidity === 'function'
        }),
      },
      {
        name: 'Clipboard API',
        ...safeTest(() => typeof navigator !== 'undefined' && typeof navigator.clipboard !== 'undefined'),
      },
    ],
  })

  /* ─── Miscellaneous ─── */
  categories.push({
    title: 'Miscellaneous',
    tests: [
      { name: 'History API', ...safeTest(() => typeof history !== 'undefined' && typeof history.pushState === 'function') },
      { name: 'matchMedia', ...safeTest(() => typeof matchMedia === 'function') },
      { name: 'queueMicrotask', ...safeTest(() => typeof queueMicrotask === 'function') },
      { name: 'structuredClone', ...safeTest(() => typeof structuredClone === 'function') },
      {
        name: 'getBoundingClientRect',
        ...safeTest(() => {
          const el = document.createElement('div')
          return typeof el.getBoundingClientRect === 'function'
        }, 'Returns zeros until onscreen — see async rendering'),
      },
      {
        name: 'getComputedStyle',
        ...safeTest(() => typeof getComputedStyle === 'function'),
      },
      {
        name: 'requestIdleCallback',
        ...safeTest(() => typeof requestIdleCallback === 'function'),
      },
      {
        name: 'Blob',
        ...safeTest(() => typeof Blob === 'function'),
      },
      {
        name: 'File',
        ...safeTest(() => typeof File === 'function'),
      },
      {
        name: 'FileReader',
        ...safeTest(() => typeof FileReader === 'function'),
      },
    ],
  })

  return categories
}

/* ── UI Components ── */

const statusColors: Record<TestStatus, string> = {
  pass: 'bg-emerald-100 text-emerald-700 dark:bg-emerald-900 dark:text-emerald-300',
  fail: 'bg-red-100 text-red-700 dark:bg-red-900 dark:text-red-300',
  partial: 'bg-amber-100 text-amber-700 dark:bg-amber-900 dark:text-amber-300',
  skip: 'bg-slate-100 text-slate-500 dark:bg-slate-800 dark:text-slate-400',
}

const statusIcons: Record<TestStatus, string> = {
  pass: '\u2713',
  fail: '\u2717',
  partial: '~',
  skip: '-',
}

function StatusBadge({ status }: { status: TestStatus }) {
  return (
    <span className={`inline-flex h-6 w-6 items-center justify-center rounded-full text-xs font-bold ${statusColors[status]}`}>
      {statusIcons[status]}
    </span>
  )
}

function CategorySection({ category }: { category: TestCategory }) {
  const passCount = category.tests.filter((t) => t.status === 'pass').length
  const total = category.tests.length

  return (
    <div className="rounded-2xl border border-slate-200 bg-white p-5 shadow-sm dark:border-slate-800 dark:bg-slate-900/60">
      <div className="flex items-center justify-between">
        <h2 className="text-base font-semibold text-slate-900 dark:text-slate-100">{category.title}</h2>
        <span className="text-xs text-slate-500 dark:text-slate-400">
          {passCount}/{total} pass
        </span>
      </div>
      <div className="mt-3 flex flex-col gap-1.5">
        {category.tests.map((test) => (
          <div
            key={test.name}
            className="flex items-center justify-between rounded-lg border border-slate-100 px-3 py-1.5 dark:border-slate-800"
          >
            <div className="min-w-0 flex-1 flex flex-col">
              <span className="text-sm font-medium text-slate-800 dark:text-slate-200">{test.name}</span>
              {test.detail && <span className="truncate text-xs text-slate-500 dark:text-slate-400">{test.detail}</span>}
            </div>
            <div className="ml-2 shrink-0">
              <StatusBadge status={test.status} />
            </div>
          </div>
        ))}
      </div>
    </div>
  )
}

/* ── Page ── */

function CompatDemoPage() {
  const { navigate } = useNavigate()
  const [filter, setFilter] = useState<'all' | 'pass' | 'fail'>('all')

  const categories = useMemo(() => runAllTests(), [])

  const filtered = useMemo(() => {
    if (filter === 'all') return categories
    return categories
      .map((cat) => ({
        ...cat,
        tests: cat.tests.filter((t) => (filter === 'pass' ? t.status === 'pass' : t.status === 'fail')),
      }))
      .filter((cat) => cat.tests.length > 0)
  }, [categories, filter])

  const totalPass = categories.reduce((n, c) => n + c.tests.filter((t) => t.status === 'pass').length, 0)
  const totalFail = categories.reduce((n, c) => n + c.tests.filter((t) => t.status === 'fail').length, 0)
  const totalAll = categories.reduce((n, c) => n + c.tests.length, 0)

  return (
    <div className="mx-auto flex min-h-screen max-w-5xl flex-col gap-5 px-6 py-6">
      {/* Header */}
      <header className="flex items-start gap-4">
        <button
          onClick={() => navigate(-1)}
          className="mt-1 flex h-10 w-10 items-center justify-center rounded-full border border-slate-200 bg-white shadow-sm dark:border-slate-800 dark:bg-slate-900"
          aria-label="Go Back"
        >
          <svg className="h-5 w-5 text-slate-700 dark:text-slate-300" fill="none" viewBox="0 0 24 24" stroke="currentColor" strokeWidth="2.5">
            <path strokeLinecap="round" strokeLinejoin="round" d="M15 19l-7-7 7-7" />
          </svg>
        </button>
        <div>
          <h1 className="text-2xl font-semibold text-slate-900 dark:text-slate-100">API Compatibility</h1>
          <p className="mt-1 text-sm text-slate-600 dark:text-slate-400">
            Runtime detection of Web API support in this environment.
          </p>
        </div>
      </header>

      {/* Summary bar */}
      <div className="flex flex-wrap items-center gap-3 rounded-xl border border-slate-200 bg-slate-50 px-5 py-3 dark:border-slate-800 dark:bg-slate-900/40">
        <span className="text-sm font-medium text-slate-900 dark:text-slate-100">
          {totalPass}/{totalAll} APIs detected
        </span>
        <span className="text-xs text-emerald-600 dark:text-emerald-400">{totalPass} supported</span>
        <span className="text-xs text-red-600 dark:text-red-400">{totalFail} missing</span>

        <div className="ml-auto flex gap-2">
          {(['all', 'pass', 'fail'] as const).map((f) => (
            <button
              key={f}
              onClick={() => setFilter(f)}
              className={`rounded-full px-3 py-1 text-xs font-medium transition ${
                filter === f
                  ? 'bg-indigo-500 text-white'
                  : 'border border-slate-300 text-slate-700 dark:border-slate-600 dark:text-slate-300'
              }`}
            >
              {f === 'all' ? 'All' : f === 'pass' ? 'Supported' : 'Missing'}
            </button>
          ))}
        </div>
      </div>

      {/* Test categories */}
      <div className="flex flex-col gap-4">
        {filtered.map((cat) => (
          <CategorySection key={cat.title} category={cat} />
        ))}
      </div>

      <footer className="mt-auto pb-4 text-center text-xs text-slate-500 dark:text-slate-400">
        Tests run at page load via runtime feature detection. Results may differ between WebF and browser.
      </footer>
    </div>
  )
}

export default CompatDemoPage

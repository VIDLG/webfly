import { useState } from 'react'
import { useLocation, WebFRouter } from '@openwebf/react-router'

function StateDemoPage() {
  const location = useLocation()
  const [counter, setCounter] = useState(0)

  // history.state is the raw value from the delegate (JSON string).
  // useLocation().state is the parsed version provided by the router.
  const rawState = typeof history !== 'undefined' ? history.state : null
  const routerState = location.state

  const handlePushState = () => {
    const next = counter + 1
    setCounter(next)
    WebFRouter.pushState(
      { from: 'js', action: 'pushState', counter: next },
      '/state',
    )
  }

  return (
    <div className="mx-auto flex min-h-screen max-w-3xl flex-col gap-6 px-6 py-12">
      <header>
        <h1 className="text-3xl font-semibold text-slate-900 dark:text-slate-100">
          State Demo
        </h1>
        <p className="mt-2 text-sm text-slate-600 dark:text-slate-400">
          Demonstrates <code className="rounded bg-white/70 px-1.5 py-0.5 text-sky-600 dark:bg-slate-900/60">history.state</code> flowing between Flutter host and JS.
        </p>
      </header>

      {/* State from Flutter (initial navigation) */}
      <div className="rounded-2xl border border-slate-200 bg-white p-6 shadow-sm dark:border-slate-800 dark:bg-slate-900/60">
        <h2 className="text-lg font-semibold text-slate-900 dark:text-slate-100">
          Router State (useLocation)
        </h2>
        <p className="mt-1 text-xs text-slate-500 dark:text-slate-400">
          Value from <code>useLocation().state</code> — parsed by the router.
        </p>
        <pre className="mt-3 overflow-x-auto rounded-xl bg-slate-100 p-4 text-xs text-slate-700 dark:bg-slate-800 dark:text-slate-300">
          {JSON.stringify(routerState, null, 2) ?? 'null'}
        </pre>
      </div>

      <div className="rounded-2xl border border-slate-200 bg-white p-6 shadow-sm dark:border-slate-800 dark:bg-slate-900/60">
        <h2 className="text-lg font-semibold text-slate-900 dark:text-slate-100">
          Raw history.state
        </h2>
        <p className="mt-1 text-xs text-slate-500 dark:text-slate-400">
          Value from <code>history.state</code> — the raw delegate return value.
        </p>
        <pre className="mt-3 overflow-x-auto rounded-xl bg-slate-100 p-4 text-xs text-slate-700 dark:bg-slate-800 dark:text-slate-300">
          {typeof rawState === 'string' ? rawState : JSON.stringify(rawState, null, 2) ?? 'null'}
        </pre>
      </div>

      {/* JS-side state push */}
      <div className="rounded-2xl border border-slate-200 bg-white p-6 shadow-sm dark:border-slate-800 dark:bg-slate-900/60">
        <h2 className="text-lg font-semibold text-slate-900 dark:text-slate-100">
          Push State from JS
        </h2>
        <p className="mt-1 text-xs text-slate-500 dark:text-slate-400">
          Calls <code>WebFRouter.pushState()</code> with a counter to verify JS-originated state updates.
        </p>
        <div className="mt-4 flex items-center gap-4">
          <button
            className="rounded-full bg-gradient-to-r from-indigo-500 to-purple-600 px-5 py-2 text-sm font-semibold text-white transition hover:from-indigo-400 hover:to-purple-500 active:scale-[0.98] active:opacity-80 focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-purple-400/70"
            onClick={handlePushState}
          >
            Push State (counter: {counter})
          </button>
        </div>
      </div>

      <div className="flex gap-3">
        <button
          className="rounded-full bg-sky-500 px-5 py-2 text-sm font-semibold text-white transition hover:bg-sky-400"
          onClick={() => WebFRouter.back()}
        >
          Go Back
        </button>
      </div>
    </div>
  )
}

export default StateDemoPage

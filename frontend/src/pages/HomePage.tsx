import { useNavigate } from '@openwebf/react-router'
import { useTheme } from '../hooks/theme'

function HomePage() {
  const { navigate } = useNavigate()
  const { theme, toggleTheme } = useTheme()

  return (
    <div className="mx-auto flex min-h-screen max-w-5xl flex-col gap-8 px-6 py-6">
      <header className="space-y-2">
          <div className="flex items-start justify-between">
            <div className="space-y-2">
              <p className="text-sm uppercase tracking-[0.35em] text-slate-600 dark:text-slate-400">
                WebFly Demo Hub
              </p>
              <h1 className="text-4xl font-semibold text-slate-900 sm:text-5xl dark:text-slate-100">Feature Showcase</h1>
              <p className="text-base text-slate-600 dark:text-slate-400">
                Quick entry points to key demos: dynamic UI, routing, and feature pages.
              </p>
            </div>
            <button
              onClick={toggleTheme}
              className="rounded-full border border-slate-300 bg-white/70 p-3 text-slate-900 transition hover:opacity-90 active:scale-[0.95] focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-slate-400/60 dark:border-slate-700 dark:bg-slate-900/60 dark:text-slate-100"
              aria-label={`Switch to ${theme === 'dark' ? 'light' : 'dark'} theme`}
              title={`Current: ${theme} theme`}
            >
              {theme === 'dark' ? '☀️' : '🌙'}
            </button>
          </div>
        </header>

        {/* ... rest of the content ... */}


      <section className="grid gap-4 sm:grid-cols-2">
        <div className="rounded-2xl border border-slate-200 bg-white p-6 shadow-sm dark:border-slate-800 dark:bg-slate-900/60">
          <h2 className="text-lg font-semibold text-slate-900 dark:text-slate-100">💡 Dynamic UI Demo</h2>
          <p className="mt-2 text-sm text-slate-600 dark:text-slate-400">
            Runtime component loading + interactive LED effects preview.
          </p>
          <div className="mt-4 flex flex-wrap gap-3">
            <button
              className="rounded-full bg-gradient-to-r from-indigo-500 to-purple-600 px-5 py-2 text-sm font-semibold text-white transition hover:from-indigo-400 hover:to-purple-500 active:scale-[0.98] active:opacity-80 focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-purple-400/70"
              onClick={() => navigate('/led')}
            >
              🌈 LED Strip Control
            </button>
          </div>
        </div>

        <div className="rounded-2xl border border-slate-200 bg-white p-6 shadow-sm dark:border-slate-800 dark:bg-slate-900/60">
          <h2 className="text-lg font-semibold text-slate-900 dark:text-slate-100">🧭 Navigation</h2>
          <p className="mt-2 text-sm text-slate-600 dark:text-slate-400">
            Each route opens as an independent native page (WebF router stack).
          </p>
          <div className="mt-4 flex flex-wrap gap-3">
            <button
              className="rounded-full bg-sky-500 px-5 py-2 text-sm font-semibold text-white transition hover:bg-sky-400 active:scale-[0.98] active:opacity-80 focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-sky-400/70"
              onClick={() => navigate('/profile', { state: { from: 'home' } })}
            >
              Go to Profile
            </button>
            <button
              className="rounded-full border border-slate-300 bg-transparent px-5 py-2 text-sm text-slate-900 transition hover:opacity-90 active:scale-[0.98] active:opacity-80 focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-slate-400/60 dark:border-slate-700 dark:text-slate-100"
              onClick={() => navigate('/products')}
            >
              View Products
            </button>
            <button
              onClick={() => navigate('/settings')}
              className="rounded-full border border-slate-300 bg-transparent px-5 py-2 text-sm text-slate-900 transition hover:opacity-90 active:scale-[0.98] active:opacity-80 focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-slate-400/60 dark:border-slate-700 dark:text-slate-100"
            >
              Open Settings
            </button>
          </div>
        </div>
      </section>

      <footer className="mt-auto pb-4 text-sm text-slate-600 dark:text-slate-400">
          Tip: Use the system back gesture/button to return.
        </footer>
    </div>
  )
}

export default HomePage

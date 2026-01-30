import { useNavigate } from '@openwebf/react-router'
import { useTheme } from '../hooks/theme'

function HomePage() {
  const { navigate } = useNavigate()
  const { theme, toggleTheme } = useTheme()

  return (
    <div className="mx-auto flex min-h-screen max-w-5xl flex-col gap-8 px-6 py-12">
      <header className="space-y-2">
        <div className="flex items-start justify-between">
          <div className="space-y-2">
            <p className="text-sm uppercase tracking-[0.35em] text-slate-400">
              WebFly Demo Hub
            </p>
            <h1 className="text-4xl font-semibold text-white sm:text-5xl">Feature Showcase</h1>
            <p className="text-base text-slate-300">
              Quick entry points to key demos: dynamic UI, routing, and feature pages.
            </p>
          </div>
          <button
            onClick={toggleTheme}
            className="rounded-full border border-slate-700 bg-slate-900/60 p-3 text-slate-300 transition hover:border-slate-500 hover:bg-slate-800/60 active:scale-[0.95] focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-slate-400/60"
            aria-label={`Switch to ${theme === 'dark' ? 'light' : 'dark'} theme`}
            title={`Current: ${theme} theme`}
          >
            {theme === 'dark' ? '☀️' : '🌙'}
          </button>
        </div>
      </header>

      <section className="grid gap-4 sm:grid-cols-2">
        <div className="rounded-2xl border border-slate-800 bg-slate-900/60 p-6">
          <h2 className="text-lg font-semibold text-white">💡 Dynamic UI Demo</h2>
          <p className="mt-2 text-sm text-slate-400">
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

        <div className="rounded-2xl border border-slate-800 bg-slate-900/60 p-6">
          <h2 className="text-lg font-semibold text-white">🧭 Navigation</h2>
          <p className="mt-2 text-sm text-slate-400">
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
              className="rounded-full border border-slate-700 px-5 py-2 text-sm text-slate-200 transition hover:border-slate-500 active:scale-[0.98] active:opacity-80 focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-slate-400/60"
              onClick={() => navigate('/products')}
            >
              View Products
            </button>
            <button
              onClick={() => navigate('/settings')}
              className="rounded-full border border-slate-700 px-5 py-2 text-sm text-slate-200 transition hover:border-slate-500 active:scale-[0.98] active:opacity-80 focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-slate-400/60"
            >
              Open Settings
            </button>
          </div>
        </div>
      </section>

      <footer className="mt-auto pb-4 text-sm text-slate-500">
        Tip: Use the system back gesture/button to return.
      </footer>
    </div>
  )
}

export default HomePage

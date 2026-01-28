import { useNavigate } from '@openwebf/react-router'

function HomePage() {
  const { navigate } = useNavigate()
  return (
    <div className="mx-auto flex min-h-screen max-w-5xl flex-col gap-8 px-6 py-12">
      <header className="space-y-2">
        <p className="text-sm uppercase tracking-[0.35em] text-slate-400">
          WebF Routing Demo
        </p>
        <h1 className="text-4xl font-semibold text-white sm:text-5xl">
          Hybrid Routing with Native Transitions
        </h1>
        <p className="text-base text-slate-300">
          Each route is an independent native page, managed by WebF Router navigation stack.
        </p>
      </header>

      <section className="grid gap-4 sm:grid-cols-2">
        <div className="rounded-2xl border border-slate-800 bg-slate-900/60 p-6">
          <h2 className="text-lg font-semibold text-white">💡 Dynamic UI Demo</h2>
          <p className="mt-2 text-sm text-slate-400">
            Experience dynamic component loading with LED strip effects.
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
          <h2 className="text-lg font-semibold text-white">Imperative Navigation</h2>
          <p className="mt-2 text-sm text-slate-400">
            Use `useNavigate` to open new pages.
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
          </div>
        </div>

        <div className="rounded-2xl border border-slate-800 bg-slate-900/60 p-6">
          <h2 className="text-lg font-semibold text-white">More Navigation</h2>
          <p className="mt-2 text-sm text-slate-400">
            Additional navigation options using `navigate()`.
          </p>
          <div className="mt-4 flex flex-wrap gap-3">
            <button
              onClick={() => navigate('/settings')}
              className="rounded-full border border-slate-700 px-5 py-2 text-sm text-slate-200 transition hover:border-slate-500 active:scale-[0.98] active:opacity-80 focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-slate-400/60"
            >
              Open Settings
            </button>
            <button
              onClick={() => navigate('/products')}
              className="rounded-full border border-slate-700 px-5 py-2 text-sm text-slate-200 transition hover:border-slate-500 active:scale-[0.98] active:opacity-80 focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-slate-400/60"
            >
              Browse Products
            </button>
          </div>
        </div>
      </section>

      <footer className="text-sm text-slate-500">
        Tip: Use system back button to return to previous page.
      </footer>
    </div>
  )
}

export default HomePage

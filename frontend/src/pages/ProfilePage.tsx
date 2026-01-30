import { useLocation, WebFRouter } from '@openwebf/react-router'

function ProfilePage() {
  const location = useLocation()
  const from = (location.state as { from?: string } | null)?.from ?? 'unknown'

  return (
    <div className="mx-auto flex min-h-screen max-w-3xl flex-col gap-6 px-6 py-12">
      <header>
        <h1 className="text-3xl font-semibold text-slate-900 dark:text-slate-100">Profile</h1>
        <p className="mt-2 text-sm text-slate-600 dark:text-slate-400">
          This is an independent native page, from: {from}
        </p>
      </header>

      <div className="rounded-2xl border border-slate-200 bg-white p-6 text-sm text-slate-600 dark:border-slate-800 dark:bg-slate-900/60 dark:text-slate-400">
        💡 <strong>Using useNavigate() Hook:</strong> This page demonstrates programmatic navigation with the <code className="rounded bg-white/70 px-1.5 py-0.5 text-sky-600 dark:bg-slate-900/60">useNavigate()</code> hook.
      </div>

      <div className="flex gap-3">
        <button
          className="rounded-full bg-sky-500 px-5 py-2 text-sm font-semibold text-white transition hover:bg-sky-400"
          onClick={() => WebFRouter.back()}
        >
          Go Back
        </button>
        <button
          className="rounded-full border border-slate-300 px-5 py-2 text-sm text-slate-900 transition hover:opacity-90 dark:border-slate-700 dark:text-slate-100"
          onClick={() =>
            WebFRouter.pushState({ from: 'profile' }, '/settings')
          }
        >
          Go to Settings
        </button>
      </div>
    </div>
  )
}

export default ProfilePage

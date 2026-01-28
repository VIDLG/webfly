import { useLocation, WebFRouter } from '@openwebf/react-router'

function ProfilePage() {
  const location = useLocation()
  const from = (location.state as { from?: string } | null)?.from ?? 'unknown'

  return (
    <div className="mx-auto flex min-h-screen max-w-3xl flex-col gap-6 px-6 py-12">
      <header>
        <h1 className="text-3xl font-semibold text-white">Profile</h1>
        <p className="mt-2 text-sm text-slate-400">
          This is an independent native page, from: {from}
        </p>
      </header>

      <div className="rounded-2xl border border-slate-800 bg-slate-900/60 p-6 text-sm text-slate-300">
        💡 <strong>Using useNavigate() Hook:</strong> This page demonstrates programmatic navigation with the <code className="rounded bg-slate-700 px-1.5 py-0.5 text-sky-400">useNavigate()</code> hook.
      </div>

      <div className="flex gap-3">
        <button
          className="rounded-full bg-sky-500 px-5 py-2 text-sm font-semibold text-white transition hover:bg-sky-400"
          onClick={() => WebFRouter.back()}
        >
          Go Back
        </button>
        <button
          className="rounded-full border border-slate-700 px-5 py-2 text-sm text-slate-200 transition hover:border-slate-500"
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

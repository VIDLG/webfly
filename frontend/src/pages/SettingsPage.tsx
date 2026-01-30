import { useNavigate } from '@openwebf/react-router'
import { useTheme } from '../hooks/theme'

function SettingsPage() {
  const { navigate } = useNavigate()
  const { theme, themePreference, setThemePreference } = useTheme()

  const handleSave = () => {
    navigate('/home', { state: { from: 'settings' }, replace: true })
  }

  return (
    <div className="mx-auto flex min-h-screen max-w-3xl flex-col gap-6 px-6 py-12">
      <header>
        <h1 className="text-3xl font-semibold text-white">Settings</h1>
        <p className="mt-2 text-sm text-slate-400">
          Using replaceState will replace current page, no back button available.
        </p>
      </header>

      <div className="rounded-2xl border border-slate-800 bg-slate-900/60 p-6">
        <h2 className="text-lg font-semibold text-white">Theme</h2>
        <p className="mt-1 text-xs text-slate-400">
          Current: {theme} {themePreference === 'system' && '(system)'}
        </p>
        <div className="mt-3 space-y-3">
          <label className="flex items-center gap-3">
            <input
              type="radio"
              name="theme"
              checked={themePreference === 'light'}
              onChange={() => setThemePreference('light')}
              className="h-5 w-5"
            />
            <span className="text-sm text-slate-300">Light</span>
          </label>
          <label className="flex items-center gap-3">
            <input
              type="radio"
              name="theme"
              checked={themePreference === 'dark'}
              onChange={() => setThemePreference('dark')}
              className="h-5 w-5"
            />
            <span className="text-sm text-slate-300">Dark</span>
          </label>
          <label className="flex items-center gap-3">
            <input
              type="radio"
              name="theme"
              checked={themePreference === 'system'}
              onChange={() => setThemePreference('system')}
              className="h-5 w-5"
            />
            <span className="text-sm text-slate-300">System</span>
          </label>
        </div>
      </div>

      <div className="flex gap-3">
        <button
          className="rounded-full bg-sky-500 px-5 py-2 text-sm font-semibold text-white transition hover:bg-sky-400"
          onClick={handleSave}
        >
          Save & Go Home
        </button>
        <button
          className="rounded-full border border-slate-700 px-5 py-2 text-sm text-slate-200 transition hover:border-slate-500"
          onClick={() => navigate(-1)}
        >
          Cancel
        </button>
      </div>

      <div className="rounded-2xl border border-slate-800 bg-slate-900/60 p-4 text-sm text-slate-400">
        💡 <strong>Using useNavigate():</strong> Save button uses <code className="rounded bg-slate-700 px-1.5 py-0.5 text-sky-400">navigate('/home', {'{'} state: {'{'} from: 'settings' {'}'}, replace: true {'}'})</code> to navigate back home.
      </div>
    </div>
  )
}

export default SettingsPage

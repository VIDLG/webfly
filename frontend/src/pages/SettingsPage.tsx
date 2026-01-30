import { useEffect, useState } from 'react'
import { useNavigate } from '@openwebf/react-router'
import { useTheme } from '../hooks/theme'

type ThemePreference = 'light' | 'dark' | 'system'

function ThemeOptionRow({
  label,
  value,
  selected,
  onSelect,
}: {
  label: string
  value: ThemePreference
  selected: boolean
  onSelect: (value: ThemePreference) => void
}) {
  return (
    <div
      role="radio"
      aria-checked={selected}
      tabIndex={0}
      className={
        'flex cursor-pointer select-none items-center justify-between rounded-xl border px-4 py-3 transition hover:opacity-90 ' +
        (selected
          ? 'border-sky-500 bg-white dark:border-sky-400 dark:bg-slate-900/60'
          : 'border-slate-300 bg-white/70 dark:border-slate-700 dark:bg-slate-900/60')
      }
      onClick={() => onSelect(value)}
      onKeyDown={(e) => {
        if (e.key === 'Enter' || e.key === ' ') {
          e.preventDefault()
          onSelect(value)
        }
      }}
    >
      <span className="text-sm font-medium text-slate-900 dark:text-slate-100">{label}</span>
      <span
        aria-hidden="true"
        className={
          'relative h-5 w-5 rounded-full border ' +
          (selected
            ? 'border-sky-500 dark:border-sky-400'
            : 'border-slate-400 dark:border-slate-500')
        }
      >
        {selected ? (
          <span className="absolute left-1/2 top-1/2 h-2.5 w-2.5 -translate-x-1/2 -translate-y-1/2 rounded-full bg-sky-500 dark:bg-sky-400" />
        ) : null}
      </span>
    </div>
  )
}

function SettingsPage() {
  const { navigate } = useNavigate()
  const { theme, themePreference, setThemePreference } = useTheme()
  const [selectedPreference, setSelectedPreference] = useState<ThemePreference>(themePreference)

  useEffect(() => {
    setSelectedPreference(themePreference)
  }, [themePreference])

  const handleBack = async () => {
    // Pop back to the previous page to avoid creating a mixed-theme navigation stack.
    // If there's no history to pop, fall back to home.
    try {
      navigate(-1)
    } catch {
      navigate('/home', { replace: true })
    }
  }

  return (
    <div className="mx-auto flex min-h-screen max-w-3xl flex-col gap-6 px-6 py-12">
      <header>
        <h1 className="text-3xl font-semibold text-slate-900 dark:text-slate-100">Settings</h1>
        <p className="mt-2 text-sm text-slate-600 dark:text-slate-400">App preferences</p>
      </header>

      <div className="rounded-2xl border border-slate-200 bg-white p-6 dark:border-slate-800 dark:bg-slate-900/60">
        <h2 className="text-lg font-semibold text-slate-900 dark:text-slate-100">Theme</h2>
        <p className="mt-1 text-xs text-slate-600 dark:text-slate-400">Applied: {theme} · Preference: {themePreference}</p>
        <div className="mt-3" role="radiogroup" aria-label="Theme">
          <div className="flex flex-col gap-2">
            <ThemeOptionRow
              label="Light"
              value="light"
              selected={selectedPreference === 'light'}
              onSelect={(value) => {
                setSelectedPreference(value)
                void setThemePreference(value)
              }}
            />
            <ThemeOptionRow
              label="Dark"
              value="dark"
              selected={selectedPreference === 'dark'}
              onSelect={(value) => {
                setSelectedPreference(value)
                void setThemePreference(value)
              }}
            />
            <ThemeOptionRow
              label="System"
              value="system"
              selected={selectedPreference === 'system'}
              onSelect={(value) => {
                setSelectedPreference(value)
                void setThemePreference(value)
              }}
            />
          </div>
        </div>
      </div>

      <div className="flex gap-3">
        <button
          className="rounded-full bg-sky-500 px-5 py-2 text-sm font-semibold text-white transition hover:bg-sky-400"
          onClick={handleBack}
        >
          Back
        </button>
      </div>
    </div>
  )
}

export default SettingsPage

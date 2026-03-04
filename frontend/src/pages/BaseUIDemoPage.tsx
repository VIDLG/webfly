import { useState } from 'react'
import { useNavigate } from '@openwebf/react-router'
import { Dialog } from '@base-ui/react/dialog'
import { Toggle } from '@base-ui/react/toggle'
import { Separator } from '@base-ui/react/separator'

function StatusBadge({ supported }: { supported: boolean }) {
  return (
    <span
      className={`ml-2 inline-block rounded-full px-2 py-0.5 text-xs font-medium ${
        supported
          ? 'bg-emerald-100 text-emerald-700 dark:bg-emerald-900 dark:text-emerald-300'
          : 'bg-red-100 text-red-700 dark:bg-red-900 dark:text-red-300'
      }`}
    >
      {supported ? 'Works' : 'Incompatible'}
    </span>
  )
}

function BaseUIDemoPage() {
  const { navigate } = useNavigate()
  const [togglePressed, setTogglePressed] = useState(false)

  return (
    <div className="mx-auto flex min-h-screen max-w-5xl flex-col gap-6 px-6 py-6">
      {/* Header */}
      <header className="flex items-start gap-4">
        <button
          onClick={() => navigate(-1)}
          className="group mt-1 flex h-10 w-10 items-center justify-center rounded-full border border-slate-200 bg-white shadow-sm dark:border-slate-800 dark:bg-slate-900"
          aria-label="Go Back"
        >
          <svg className="h-5 w-5 text-slate-700 dark:text-slate-300" fill="none" viewBox="0 0 24 24" stroke="currentColor" strokeWidth="2.5">
            <path strokeLinecap="round" strokeLinejoin="round" d="M15 19l-7-7 7-7" />
          </svg>
        </button>
        <div>
          <h1 className="text-2xl font-semibold text-slate-900 dark:text-slate-100">Base UI Demo</h1>
          <p className="mt-1 text-sm text-slate-600 dark:text-slate-400">
            @base-ui/react components compatibility in WebF.
          </p>
        </div>
      </header>

      {/* ── Working Components ── */}

      {/* Toggle */}
      <div className="rounded-2xl border border-slate-200 bg-white p-6 shadow-sm dark:border-slate-800 dark:bg-slate-900/60">
        <h2 className="text-lg font-semibold text-slate-900 dark:text-slate-100">
          Toggle <StatusBadge supported />
        </h2>
        <p className="mt-1 text-sm text-slate-600 dark:text-slate-400">Pressable toggle button.</p>
        <div className="mt-4 flex items-center gap-3">
          <Toggle
            pressed={togglePressed}
            onPressedChange={setTogglePressed}
            className={`rounded-lg border px-4 py-2 text-sm font-medium transition-colors ${
              togglePressed
                ? 'border-indigo-500 bg-indigo-50 text-indigo-700 dark:border-indigo-400 dark:bg-indigo-950 dark:text-indigo-300'
                : 'border-slate-300 text-slate-700 dark:border-slate-600 dark:text-slate-300'
            }`}
            aria-label="Toggle bold"
          >
            <span className="font-bold">B</span>
          </Toggle>
          <span className="text-sm text-slate-700 dark:text-slate-300">
            {togglePressed ? 'Pressed' : 'Not pressed'}
          </span>
        </div>
      </div>

      {/* Separator */}
      <div className="rounded-2xl border border-slate-200 bg-white p-6 shadow-sm dark:border-slate-800 dark:bg-slate-900/60">
        <h2 className="text-lg font-semibold text-slate-900 dark:text-slate-100">
          Separator <StatusBadge supported />
        </h2>
        <p className="mt-1 text-sm text-slate-600 dark:text-slate-400">Accessible visual divider.</p>
        <div className="mt-4 flex flex-col gap-3">
          <p className="text-sm text-slate-700 dark:text-slate-300">Content above</p>
          <Separator className="h-px w-full bg-slate-200 dark:bg-slate-700" />
          <p className="text-sm text-slate-700 dark:text-slate-300">Content below</p>
        </div>
      </div>

      {/* Dialog */}
      <div className="rounded-2xl border border-slate-200 bg-white p-6 shadow-sm dark:border-slate-800 dark:bg-slate-900/60">
        <h2 className="text-lg font-semibold text-slate-900 dark:text-slate-100">
          Dialog <StatusBadge supported />
        </h2>
        <p className="mt-1 text-sm text-slate-600 dark:text-slate-400">Modal dialog with focus trapping and backdrop.</p>
        <div className="mt-4">
          <Dialog.Root>
            <Dialog.Trigger className="rounded-full bg-indigo-500 px-5 py-2 text-sm font-semibold text-white transition hover:bg-indigo-400 active:scale-[0.98]">
              Open Dialog
            </Dialog.Trigger>
            <Dialog.Portal>
              <Dialog.Backdrop className="fixed inset-0 bg-black/40" />
              <Dialog.Popup className="fixed left-1/2 top-1/2 w-80 -translate-x-1/2 -translate-y-1/2 rounded-2xl border border-slate-200 bg-white p-6 shadow-lg dark:border-slate-700 dark:bg-slate-900">
                <Dialog.Title className="text-lg font-semibold text-slate-900 dark:text-slate-100">
                  Base UI Dialog
                </Dialog.Title>
                <Dialog.Description className="mt-2 text-sm text-slate-600 dark:text-slate-400">
                  This dialog is rendered via a portal with focus trapping and accessible keyboard interactions.
                </Dialog.Description>
                <div className="mt-4 flex justify-end">
                  <Dialog.Close className="rounded-full bg-slate-200 px-4 py-2 text-sm font-medium text-slate-900 transition hover:bg-slate-300 dark:bg-slate-700 dark:text-slate-100 dark:hover:bg-slate-600">
                    Close
                  </Dialog.Close>
                </div>
              </Dialog.Popup>
            </Dialog.Portal>
          </Dialog.Root>
        </div>
      </div>

      {/* ── Incompatible Components ── */}

      <div className="rounded-2xl border border-red-200 bg-red-50/50 p-6 dark:border-red-900 dark:bg-red-950/30">
        <h2 className="text-lg font-semibold text-slate-900 dark:text-slate-100">
          Incompatible Components
        </h2>
        <p className="mt-1 text-sm text-slate-600 dark:text-slate-400">
          These components rely on Web APIs that WebF does not fully support.
        </p>
        <div className="mt-4 flex flex-col gap-2">
          {[
            { name: 'Switch', reason: 'new PointerEvent() constructor' },
            { name: 'Checkbox', reason: 'new PointerEvent() constructor' },
            { name: 'Accordion', reason: 'compareDocumentPosition' },
            { name: 'Tabs', reason: 'compareDocumentPosition' },
            { name: 'Slider', reason: 'compareDocumentPosition' },
            { name: 'Select', reason: 'compareDocumentPosition' },
            { name: 'Menu', reason: 'compareDocumentPosition' },
            { name: 'Combobox', reason: 'compareDocumentPosition' },
            { name: 'Collapsible', reason: 'MutationObserver' },
            { name: 'Progress', reason: 'Intl.NumberFormat' },
          ].map((item) => (
            <div key={item.name} className="flex items-center justify-between rounded-lg border border-red-200 bg-white px-4 py-2 dark:border-red-900 dark:bg-slate-900/60">
              <span className="text-sm font-medium text-slate-900 dark:text-slate-100">{item.name}</span>
              <span className="text-xs text-slate-500 dark:text-slate-400">{item.reason}</span>
            </div>
          ))}
        </div>
      </div>
    </div>
  )
}

export default BaseUIDemoPage

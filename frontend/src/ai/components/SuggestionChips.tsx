/**
 * SuggestionChips — preset quick-action buttons for the AI chat.
 */

const SUGGESTIONS = [
  'Make it faster',
  'Change color to blue',
  'Add brightness control',
  'Create a sparkle effect',
]

interface SuggestionChipsProps {
  onSelect: (text: string) => void
  disabled?: boolean
}

export default function SuggestionChips({ onSelect, disabled }: SuggestionChipsProps) {
  return (
    <div className="flex flex-wrap gap-1.5 px-3 py-2">
      {SUGGESTIONS.map((s) => (
        <button
          key={s}
          onClick={() => onSelect(s)}
          disabled={disabled}
          className="rounded-full border border-slate-300 bg-white px-3 py-1 text-xs text-slate-600 transition active:scale-95 disabled:opacity-40 dark:border-slate-600 dark:bg-slate-800 dark:text-slate-400"
        >
          {s}
        </button>
      ))}
    </div>
  )
}

/**
 * ChatInput — native text input for the AI chat panel.
 *
 * Uses FlutterCupertinoInput for proper native keyboard interaction in WebF.
 */

import { useState, useCallback, useRef } from 'react'
import { FlutterCupertinoInput } from '@openwebf/react-cupertino-ui'
import type { FlutterCupertinoInputElement } from '@openwebf/react-cupertino-ui'

interface ChatInputProps {
  onSend: (text: string) => void
  disabled?: boolean
}

export default function ChatInput({ onSend, disabled }: ChatInputProps) {
  const [text, setText] = useState('')
  const inputRef = useRef<FlutterCupertinoInputElement>(null)

  const handleSend = useCallback(() => {
    const trimmed = text.trim()
    if (!trimmed || disabled) return
    onSend(trimmed)
    setText('')
    inputRef.current?.clear()
  }, [text, disabled, onSend])

  return (
    <div className="flex items-center gap-2 p-2 border-t border-slate-200 dark:border-slate-700">
      <div className="flex-1">
        <FlutterCupertinoInput
          ref={inputRef}
          val={text}
          placeholder="Ask AI to modify the effect..."
          disabled={disabled}
          onInput={(e: CustomEvent<string>) => setText(e.detail)}
          onSubmit={() => handleSend()}
          clearable
        />
      </div>
      <button
        onClick={handleSend}
        disabled={disabled || !text.trim()}
        className="rounded-lg bg-sky-500 px-3 py-2 text-sm font-semibold text-white transition active:scale-95 disabled:opacity-40"
      >
        Send
      </button>
    </div>
  )
}

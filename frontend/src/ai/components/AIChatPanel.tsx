/**
 * AIChatPanel — AI chat panel that opens as a native half-screen bottom sheet.
 *
 * Uses FlutterCupertinoModalPopup for the overlay container so it doesn't
 * affect the page layout and avoids WebF CSS overflow issues.
 *
 * Contains: message list, suggestion chips, native text input, and config gear button.
 */

import { useEffect, useRef, useCallback } from 'react'
import { FlutterCupertinoModalPopup } from '@openwebf/react-cupertino-ui'
import type { FlutterCupertinoModalPopupElement } from '@openwebf/react-cupertino-ui'
import { useAIStore } from '../aiStore.js'
import { useAIEffectChat } from '../useAIEffectChat.js'
import type { AIEffectController } from '../tools/types.js'
import ChatMessage from './ChatMessage.js'
import ChatInput from './ChatInput.js'
import SuggestionChips from './SuggestionChips.js'
import AIConfigDialog from './AIConfigDialog.js'

/** Height of the bottom sheet in logical pixels */
const SHEET_HEIGHT = 420

interface AIChatPanelProps {
  controller: AIEffectController | null
}

export default function AIChatPanel({ controller }: AIChatPanelProps) {
  const { panelOpen, setPanelOpen, setConfigOpen, error } = useAIStore()
  const { messages, sendMessage, loading } = useAIEffectChat(controller)
  const scrollRef = useRef<HTMLDivElement>(null)
  const popupRef = useRef<FlutterCupertinoModalPopupElement>(null)

  // Sync store state → native popup
  useEffect(() => {
    if (panelOpen) {
      popupRef.current?.show()
    } else {
      popupRef.current?.hide()
    }
  }, [panelOpen])

  // Auto-scroll to bottom when messages change
  useEffect(() => {
    if (scrollRef.current) {
      scrollRef.current.scrollTop = scrollRef.current.scrollHeight
    }
  }, [messages])

  const handleOpen = useCallback(() => {
    setPanelOpen(true)
  }, [setPanelOpen])

  const handleClose = useCallback(() => {
    setPanelOpen(false)
  }, [setPanelOpen])

  return (
    <>
      {/* Trigger button — always visible when panel is closed */}
      <button
        onClick={handleOpen}
        className="w-full rounded-xl border border-sky-300 bg-sky-50 py-3 text-sm font-semibold text-sky-600 transition active:scale-[0.98] dark:border-sky-800 dark:bg-sky-950/40 dark:text-sky-400"
      >
        AI Assistant
        {messages.length > 0 && (
          <span className="ml-2 inline-block rounded-full bg-sky-500 px-1.5 py-0.5 text-[10px] font-bold text-white align-middle">
            {messages.filter((m) => m.role === 'assistant' && !m.pending).length}
          </span>
        )}
      </button>

      {/* Native half-screen bottom sheet */}
      <FlutterCupertinoModalPopup
        ref={popupRef}
        height={SHEET_HEIGHT}
        maskClosable
        onClose={handleClose}
      >
        <div
          className="flex flex-col bg-white dark:bg-slate-900"
          style={{ height: `${SHEET_HEIGHT}px` }}
        >
          {/* Header */}
          <div className="flex items-center justify-between px-3 py-2 border-b border-slate-200 dark:border-slate-700">
            <span className="text-sm font-bold text-slate-700 dark:text-slate-300">
              AI Assistant
            </span>
            <div className="flex items-center gap-1">
              <button
                onClick={() => setConfigOpen(true)}
                className="rounded-lg p-1.5 text-slate-400 transition"
                title="AI Settings"
              >
                <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
                  <circle cx="12" cy="12" r="3" />
                  <path d="M19.4 15a1.65 1.65 0 0 0 .33 1.82l.06.06a2 2 0 0 1 0 2.83 2 2 0 0 1-2.83 0l-.06-.06a1.65 1.65 0 0 0-1.82-.33 1.65 1.65 0 0 0-1 1.51V21a2 2 0 0 1-2 2 2 2 0 0 1-2-2v-.09A1.65 1.65 0 0 0 9 19.4a1.65 1.65 0 0 0-1.82.33l-.06.06a2 2 0 0 1-2.83 0 2 2 0 0 1 0-2.83l.06-.06A1.65 1.65 0 0 0 4.68 15a1.65 1.65 0 0 0-1.51-1H3a2 2 0 0 1-2-2 2 2 0 0 1 2-2h.09A1.65 1.65 0 0 0 4.6 9a1.65 1.65 0 0 0-.33-1.82l-.06-.06a2 2 0 0 1 0-2.83 2 2 0 0 1 2.83 0l.06.06A1.65 1.65 0 0 0 9 4.68a1.65 1.65 0 0 0 1-1.51V3a2 2 0 0 1 2-2 2 2 0 0 1 2 2v.09a1.65 1.65 0 0 0 1 1.51 1.65 1.65 0 0 0 1.82-.33l.06-.06a2 2 0 0 1 2.83 0 2 2 0 0 1 0 2.83l-.06.06A1.65 1.65 0 0 0 19.4 9a1.65 1.65 0 0 0 1.51 1H21a2 2 0 0 1 2 2 2 2 0 0 1-2 2h-.09a1.65 1.65 0 0 0-1.51 1z" />
                </svg>
              </button>
              <button
                onClick={handleClose}
                className="rounded-lg p-1.5 text-slate-400 transition"
                title="Close panel"
              >
                <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
                  <line x1="18" y1="6" x2="6" y2="18" />
                  <line x1="6" y1="6" x2="18" y2="18" />
                </svg>
              </button>
            </div>
          </div>

          {/* Messages area — scrollable, takes remaining space */}
          <div
            ref={scrollRef}
            className="overflow-y-auto"
            style={{ flex: 1 }}
          >
            {messages.length === 0 ? (
              <div className="p-4 text-center text-sm text-slate-400 dark:text-slate-500">
                Ask me to modify the effect, change colors, adjust speed, or create something new.
              </div>
            ) : (
              messages.map((msg) => <ChatMessage key={msg.id} msg={msg} />)
            )}
          </div>

          {/* Error display */}
          {error && (
            <div className="px-3 py-1.5 text-xs text-red-500 bg-red-50 dark:bg-red-950/30">
              {error}
            </div>
          )}

          {/* Suggestions (show when no messages) */}
          {messages.length === 0 && (
            <SuggestionChips onSelect={sendMessage} disabled={loading} />
          )}

          {/* Input area */}
          <ChatInput onSend={sendMessage} disabled={loading} />
        </div>
      </FlutterCupertinoModalPopup>

      {/* Config dialog */}
      <AIConfigDialog />
    </>
  )
}

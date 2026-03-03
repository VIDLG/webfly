/**
 * ChatMessage — renders a single message in the AI chat panel.
 */

import type { ChatMessage as ChatMessageType } from '../aiStore.js'

export default function ChatMessage({ msg }: { msg: ChatMessageType }) {
  if (msg.role === 'tool') {
    return (
      <div className="px-3 py-1.5 text-xs text-slate-500 dark:text-slate-500 border-l-2 border-slate-300 dark:border-slate-700 ml-2">
        <span className="font-semibold">{msg.toolName}</span>
        {msg.toolResult && (
          <pre className="mt-1 text-[10px] whitespace-pre-wrap break-words font-mono text-slate-400 dark:text-slate-600 max-h-[80px] overflow-y-auto">
            {msg.toolResult}
          </pre>
        )}
      </div>
    )
  }

  const isUser = msg.role === 'user'

  return (
    <div className={`px-3 py-2 ${isUser ? 'text-right' : ''}`}>
      <div
        className={`inline-block max-w-[85%] rounded-xl px-3 py-2 text-sm ${
          isUser
            ? 'bg-sky-500 text-white'
            : 'bg-slate-100 text-slate-800 dark:bg-slate-800 dark:text-slate-200'
        }`}
        style={{ textAlign: 'left' }}
      >
        {msg.pending ? (
          <span className="inline-block animate-pulse">Thinking...</span>
        ) : (
          <span className="whitespace-pre-wrap break-words">{msg.content}</span>
        )}
      </div>
    </div>
  )
}

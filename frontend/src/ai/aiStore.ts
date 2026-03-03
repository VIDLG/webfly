/**
 * AI panel state management via zustand.
 */

import { create } from 'zustand'

export interface ChatMessage {
  id: string
  role: 'user' | 'assistant' | 'tool'
  content: string
  /** Tool call info (for tool messages) */
  toolName?: string
  toolResult?: string
  /** Whether this message is still being generated */
  pending?: boolean
}

interface AIStore {
  /** Whether the AI chat panel is open */
  panelOpen: boolean
  togglePanel: () => void
  setPanelOpen: (open: boolean) => void

  /** Chat messages */
  messages: ChatMessage[]
  addMessage: (msg: ChatMessage) => void
  updateMessage: (id: string, update: Partial<ChatMessage>) => void
  clearMessages: () => void

  /** Whether a request is in flight */
  loading: boolean
  setLoading: (loading: boolean) => void

  /** Last error message */
  error: string | null
  setError: (error: string | null) => void

  /** Whether AI config dialog is open */
  configOpen: boolean
  setConfigOpen: (open: boolean) => void
}

export const useAIStore = create<AIStore>((set) => ({
  panelOpen: false,
  togglePanel: () => set((s) => ({ panelOpen: !s.panelOpen })),
  setPanelOpen: (open) => set({ panelOpen: open }),

  messages: [],
  addMessage: (msg) => set((s) => ({ messages: [...s.messages, msg] })),
  updateMessage: (id, update) =>
    set((s) => ({
      messages: s.messages.map((m) => (m.id === id ? { ...m, ...update } : m)),
    })),
  clearMessages: () => set({ messages: [] }),

  loading: false,
  setLoading: (loading) => set({ loading }),

  error: null,
  setError: (error) => set({ error }),

  configOpen: false,
  setConfigOpen: (open) => set({ configOpen: open }),
}))

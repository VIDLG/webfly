/**
 * useAIEffectChat — main hook that orchestrates AI interactions.
 *
 * Uses Vercel AI SDK's generateText (non-streaming) with tool calling.
 * Manages chat messages via the AI store and dispatches tool calls
 * to the AIEffectController.
 */

import { useCallback, useRef } from 'react'
import { generateText, tool, stepCountIs } from 'ai'
import { createAnthropic } from '@ai-sdk/anthropic'
import { z } from 'zod'
import { useAIStore, type ChatMessage } from './aiStore.js'
import { buildSystemPrompt } from './systemPrompt.js'
import {
  createSetConfigTool,
  createModifyUiTool,
  createModifyEffectTool,
} from './tools/index.js'
import type { AIEffectController } from './tools/types.js'
import { getApiKey, getModel } from '../storage/aiConfigStorage.js'

let messageCounter = 0
function nextId(): string {
  return `msg-${++messageCounter}-${Date.now()}`
}

/** Maximum tool-calling rounds before stopping */
const MAX_STEPS = 5

export function useAIEffectChat(controller: AIEffectController | null) {
  const controllerRef = useRef(controller)
  controllerRef.current = controller

  const {
    messages,
    addMessage,
    updateMessage,
    setLoading,
    setError,
  } = useAIStore()

  const sendMessage = useCallback(async (userText: string) => {
    const ctrl = controllerRef.current
    if (!ctrl) {
      setError('Effect controller not ready')
      return
    }

    // Check API key
    const apiKey = await getApiKey()
    if (!apiKey) {
      setError('API key not configured. Click the gear icon to set up.')
      return
    }

    const modelId = (await getModel()) || 'claude-sonnet-4-20250514'

    // Add user message
    const userMsg: ChatMessage = { id: nextId(), role: 'user', content: userText }
    addMessage(userMsg)

    // Add pending assistant message
    const assistantId = nextId()
    addMessage({ id: assistantId, role: 'assistant', content: '', pending: true })

    setLoading(true)
    setError(null)

    try {
      const anthropic = createAnthropic({ apiKey })

      // Build messages array from store (convert to AI SDK format)
      const allMessages = useAIStore.getState().messages
      const aiMessages = allMessages
        .filter((m) => !m.pending && (m.role === 'user' || m.role === 'assistant'))
        .map((m) => ({
          role: m.role as 'user' | 'assistant',
          content: m.content,
        }))

      const systemPrompt = buildSystemPrompt(ctrl.getState())

      const tools = {
        get_current_state: tool({
          description: 'Get the current state of the effect system including UI spec, effect code, parameters, and machine status.',
          inputSchema: z.object({}),
          execute: async () => ctrl.getState(),
        }),
        set_config: createSetConfigTool(ctrl),
        modify_ui: createModifyUiTool(ctrl),
        modify_effect_code: createModifyEffectTool(ctrl),
      }

      const result = await generateText({
        model: anthropic(modelId),
        system: systemPrompt,
        messages: aiMessages,
        tools,
        stopWhen: stepCountIs(MAX_STEPS),
      })

      // Extract the final text response
      const responseText = result.text || '(Action completed)'

      // Update assistant message with actual response
      updateMessage(assistantId, {
        content: responseText,
        pending: false,
      })

      // Add tool call info as separate messages for visibility
      if (result.steps) {
        for (const step of result.steps) {
          if (step.toolCalls && step.toolCalls.length > 0) {
            for (const tc of step.toolCalls) {
              addMessage({
                id: nextId(),
                role: 'tool',
                content: `Called ${tc.toolName}`,
                toolName: tc.toolName,
                toolResult: JSON.stringify('input' in tc ? tc.input : undefined, null, 2),
              })
            }
          }
        }
      }
    } catch (e) {
      const errorMsg = e instanceof Error ? e.message : String(e)
      updateMessage(assistantId, {
        content: `Error: ${errorMsg}`,
        pending: false,
      })
      setError(errorMsg)
    } finally {
      setLoading(false)
    }
  }, [addMessage, updateMessage, setLoading, setError])

  return {
    messages,
    sendMessage,
    loading: useAIStore.getState().loading,
  }
}

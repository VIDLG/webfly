/**
 * AIConfigDialog — native modal popup for configuring API key and model.
 *
 * Uses FlutterCupertinoModalPopup instead of position:fixed overlay
 * which is unreliable in WebF. API key input uses FlutterCupertinoInput.
 */

import { useState, useEffect, useCallback, useRef } from 'react'
import { FlutterCupertinoModalPopup, FlutterCupertinoInput } from '@openwebf/react-cupertino-ui'
import type { FlutterCupertinoModalPopupElement, FlutterCupertinoInputElement } from '@openwebf/react-cupertino-ui'
import { useAIStore } from '../aiStore.js'
import { getApiKey, setApiKey, getModel, setModel } from '../../storage/aiConfigStorage.js'

const MODEL_OPTIONS = [
  { id: 'claude-sonnet-4-20250514', label: 'Sonnet 4' },
  { id: 'claude-haiku-4-20250414', label: 'Haiku 4' },
]

const CONFIG_SHEET_HEIGHT = 280

export default function AIConfigDialog() {
  const { configOpen, setConfigOpen } = useAIStore()
  const [key, setKey] = useState('')
  const [model, setModelState] = useState(MODEL_OPTIONS[0].id)
  const [saving, setSaving] = useState(false)
  const popupRef = useRef<FlutterCupertinoModalPopupElement>(null)
  const inputRef = useRef<FlutterCupertinoInputElement>(null)

  // Sync store state → native popup
  useEffect(() => {
    if (configOpen) {
      popupRef.current?.show()
    } else {
      popupRef.current?.hide()
    }
  }, [configOpen])

  useEffect(() => {
    if (!configOpen) return
    void (async () => {
      const storedKey = await getApiKey()
      const storedModel = await getModel()
      if (storedKey) setKey(storedKey)
      if (storedModel) setModelState(storedModel)
    })()
  }, [configOpen])

  const handleSave = useCallback(async () => {
    setSaving(true)
    try {
      await setApiKey(key.trim())
      await setModel(model)
      setConfigOpen(false)
    } finally {
      setSaving(false)
    }
  }, [key, model, setConfigOpen])

  const handleClose = useCallback(() => {
    setConfigOpen(false)
  }, [setConfigOpen])

  return (
    <FlutterCupertinoModalPopup
      ref={popupRef}
      height={CONFIG_SHEET_HEIGHT}
      maskClosable
      onClose={handleClose}
    >
      <div
        className="bg-white dark:bg-slate-900 px-5 py-4"
        style={{ height: `${CONFIG_SHEET_HEIGHT}px` }}
      >
        <h2 className="text-lg font-bold text-slate-900 dark:text-slate-100 mb-4">AI Configuration</h2>

        <div className="space-y-4">
          {/* API Key */}
          <div>
            <label className="block text-sm font-medium text-slate-600 dark:text-slate-400 mb-1">
              Anthropic API Key
            </label>
            <FlutterCupertinoInput
              ref={inputRef}
              val={key}
              placeholder="sk-ant-..."
              type="password"
              onInput={(e: CustomEvent<string>) => setKey(e.detail)}
            />
          </div>

          {/* Model selector — button group */}
          <div>
            <label className="block text-sm font-medium text-slate-600 dark:text-slate-400 mb-1">
              Model
            </label>
            <div className="flex gap-2">
              {MODEL_OPTIONS.map((opt) => (
                <button
                  key={opt.id}
                  onClick={() => setModelState(opt.id)}
                  className={`flex-1 rounded-lg border px-3 py-2 text-sm font-medium transition ${
                    model === opt.id
                      ? 'border-sky-500 bg-sky-50 text-sky-600 dark:bg-sky-950/40 dark:text-sky-400'
                      : 'border-slate-300 bg-white text-slate-600 dark:border-slate-600 dark:bg-slate-800 dark:text-slate-400'
                  }`}
                >
                  {opt.label}
                </button>
              ))}
            </div>
          </div>
        </div>

        <div className="flex justify-end gap-2 mt-5">
          <button
            onClick={handleClose}
            className="rounded-lg border border-slate-300 px-4 py-2 text-sm font-medium text-slate-600 dark:border-slate-600 dark:text-slate-400"
          >
            Cancel
          </button>
          <button
            onClick={() => void handleSave()}
            disabled={saving || !key.trim()}
            className="rounded-lg bg-sky-500 px-4 py-2 text-sm font-semibold text-white disabled:opacity-40"
          >
            {saving ? 'Saving...' : 'Save'}
          </button>
        </div>
      </div>
    </FlutterCupertinoModalPopup>
  )
}

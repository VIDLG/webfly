import { create } from 'zustand'
import { persist } from 'zustand/middleware'

interface LedSettingsState {
  enableTypeCheck: boolean
  update: (patch: Partial<Pick<LedSettingsState, 'enableTypeCheck'>>) => void
}

export const useLedSettings = create<LedSettingsState>()(
  persist(
    (set) => ({
      enableTypeCheck: true,
      update: (patch) => set(patch),
    }),
    { name: 'webfly_led_settings' },
  ),
)

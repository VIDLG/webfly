type ResolvedTheme = 'light' | 'dark'

export const themes: Record<ResolvedTheme, Record<string, string>> = {
  dark: {
    '--bg-color': '#020617',
    '--text-color': '#f1f5f9',
    '--muted-text-color': '#94a3b8',
    '--accent-color': '#38bdf8',
    '--card-bg-color': 'rgba(15, 23, 42, 0.6)',
    '--card-border-color': '#1e293b',
    '--chip-bg-color': 'rgba(15, 23, 42, 0.6)',
    '--chip-border-color': '#334155',
  },
  light: {
    '--bg-color': '#f8fafc',
    '--text-color': '#0f172a',
    '--muted-text-color': '#475569',
    '--accent-color': '#0ea5e9',
    '--card-bg-color': '#ffffff',
    '--card-border-color': '#e2e8f0',
    '--chip-bg-color': 'rgba(255, 255, 255, 0.7)',
    '--chip-border-color': '#cbd5e1',
  },
}

type ResolvedTheme = 'light' | 'dark'

export const themes: Record<ResolvedTheme, Record<string, string>> = {
  dark: {
    '--bg-color': '#020617',
    '--text-color': '#f1f5f9',
  },
  light: {
    '--bg-color': '#ffffff',
    '--text-color': '#1f2937',
  },
}

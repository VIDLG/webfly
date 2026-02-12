// eslint-disable-next-line @typescript-eslint/no-explicit-any
export const isWebFEnvironment: boolean =
  typeof window !== 'undefined' && !!(window as any).webf

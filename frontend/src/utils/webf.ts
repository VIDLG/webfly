interface WebFGlobal {
  invokeModule?: (moduleName: string, method: string, ...args: unknown[]) => Promise<unknown>
  invokeModuleAsync?: (moduleName: string, method: string, ...args: unknown[]) => Promise<unknown>
}

/**
 * Helper function to invoke WebF module methods
 */
export async function invokeWebFModule(
  moduleName: string,
  method: string,
  ...args: unknown[]
): Promise<unknown> {
  if (typeof window === 'undefined') {
    throw new Error('Window is not available')
  }
  
  const webf = (window as Window & { webf?: WebFGlobal }).webf
  
  // Prefer invokeModuleAsync if available for async operations
  if (webf?.invokeModuleAsync) {
    return await webf.invokeModuleAsync(moduleName, method, ...args)
  }

  if (!webf?.invokeModule) {
    throw new Error('WebF invokeModule is not available')
  }
  
  return webf.invokeModule(moduleName, method, ...args)
}

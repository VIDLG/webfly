/**
 * Shared WebF bridge: invoker, response type, and helpers.
 * Used by ble.ts, app_settings.ts, permission.ts, etc.
 */

export interface WebFModuleEvent {
  detail: unknown;
}

export interface WebFGlobal {
  invokeModule?: (moduleName: string, method: string, ...args: unknown[]) => Promise<unknown>;
  invokeModuleAsync?: (moduleName: string, method: string, ...args: unknown[]) => Promise<unknown>;
  /** Subscribe to module events: eventName e.g. 'Ble:connectionStateChanged' */
  on?: (eventName: string, handler: (event: WebFModuleEvent) => void) => void;
  off?: (eventName: string, handler: (event: WebFModuleEvent) => void) => void;
  addEventListener?: (eventName: string, handler: (event: WebFModuleEvent) => void) => void;
  removeEventListener?: (eventName: string, handler: (event: WebFModuleEvent) => void) => void;
}

/** Get the webf global object (window.webf). May be undefined if not in WebF. */
export function getWebf(): WebFGlobal | undefined {
  if (typeof globalThis === 'undefined') return undefined;
  const g = globalThis as typeof globalThis & { window?: { webf?: WebFGlobal } };
  const window = g.window ?? (g as unknown as { webf?: WebFGlobal });
  return window?.webf ?? (g as unknown as { webf?: WebFGlobal }).webf;
}

/**
 * Get the WebF invoke function from window.webf.
 * Prefers invokeModuleAsync when available.
 */
export function getInvoker(): (
  moduleName: string,
  method: string,
  ...args: unknown[]
) => Promise<unknown> {
  if (typeof globalThis === 'undefined') {
    throw new Error('WebF: globalThis not available');
  }
  const g = globalThis as typeof globalThis & { window?: { webf?: WebFGlobal } };
  const window = g.window ?? (g as unknown as { webf?: WebFGlobal });
  const webf = window?.webf ?? (g as unknown as { webf?: WebFGlobal }).webf;
  if (webf?.invokeModuleAsync) {
    return (moduleName, method, ...args) => webf.invokeModuleAsync!(moduleName, method, ...args);
  }
  if (webf?.invokeModule) {
    return (moduleName, method, ...args) => webf.invokeModule!(moduleName, method, ...args);
  }
  throw new Error('WebF invokeModule is not available');
}

/**
 * Invoke a WebF native module method.
 */
export async function invokeModule<T>(
  moduleName: string,
  method: string,
  ...args: unknown[]
): Promise<T> {
  const invoker = getInvoker();
  return invoker(moduleName, method, ...args) as Promise<T>;
}

/**
 * Create a module-scoped invoker: (method, ...args) => invokeModule(moduleName, method, ...args).
 */
export function createModuleInvoker(moduleName: string) {
  return async <T>(method: string, ...args: unknown[]): Promise<T> =>
    invokeModule<T>(moduleName, method, ...args);
}

// ----------------------------------------------------------------------------
// Generic response shape (result | error)
// ----------------------------------------------------------------------------

export interface WebfResponse<T> {
  result?: T;
  error?: {
    code: number;
    message: string;
  };
}

/** Type guard: true when native returned { error: { code, message } }. */
export function isWebfError(x: unknown): x is WebfResponse<never> {
  return typeof x === 'object' && x !== null && 'error' in x;
}

/** Check if WebF bridge (window.webf.invokeModule) is available. */
export function isWebfAvailable(): boolean {
  if (typeof globalThis === 'undefined') return false;
  const g = globalThis as typeof globalThis & { window?: { webf?: WebFGlobal } };
  const window = g.window ?? (g as unknown as { webf?: WebFGlobal });
  const webf = window?.webf ?? (g as unknown as { webf?: WebFGlobal }).webf;
  return typeof webf?.invokeModule === 'function' || typeof webf?.invokeModuleAsync === 'function';
}

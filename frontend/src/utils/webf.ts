import type { Webf } from '@openwebf/webf-enterprise-typings';

/**
 * Invoke a WebF native module method. Uses global webf from @openwebf/webf-enterprise-typings.
 */
export async function invokeWebFModule(
  moduleName: string,
  method: string,
  ...args: unknown[]
): Promise<unknown> {
  if (typeof window === 'undefined') {
    throw new Error('Window is not available')
  }
  const webf = (window as typeof window & { webf?: Webf }).webf;
  if (webf?.invokeModuleAsync) {
    return await webf.invokeModuleAsync(moduleName, method, ...args);
  }
  if (!webf?.invokeModule) {
    throw new Error('WebF invokeModule is not available');
  }
  return webf.invokeModule(moduleName, method, ...args);
}

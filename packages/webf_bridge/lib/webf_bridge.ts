/** Shared WebF bridge: getWebf, module invoker, event bus. Used by webfly_ble, webfly_permission, etc. */

import { err, ok, type Result } from 'neverthrow';
import type { Webf } from '@openwebf/webf-enterprise-typings';

export type { Result };

/** Dart returns tagged union: { type: 'ok'; value: T } | { type: 'err'; message: string }. */
export type WebfResult<T> =
  | { type: 'ok'; value: T }
  | { type: 'err'; message: string };

function getWebf(): Webf | undefined {
  if (typeof globalThis === 'undefined') return undefined;
  const g = globalThis as { window?: { webf?: Webf }; webf?: Webf };
  return g.window?.webf ?? g.webf;
}

export function createModuleInvoker(moduleName: string) {
  return async <T>(method: string, ...args: unknown[]): Promise<Result<T, string>> => {
    const w = getWebf();
    const fn = w?.invokeModuleAsync;
    if (!fn) return err('WebF invokeModuleAsync is not available');
    const raw = (await fn(moduleName, method, ...args)) as WebfResult<T>;
    if (raw && typeof raw === 'object' && raw.type === 'ok') {
      return ok(raw.value);
    }
    if (raw && typeof raw === 'object' && raw.type === 'err') {
      return err(raw.message ?? 'Unknown error');
    }
    return err('Invalid response');
  };
}

// ---------------------------------------------------------------------------
// Generic WebF module event bus (module-agnostic)
// ---------------------------------------------------------------------------

export abstract class WebfModuleEventBus<
  EventType extends string,
  PayloadMap extends Record<EventType, unknown>
> {
  protected readonly handlers = new Map<string, Set<(detail: unknown) => void>>();
  private listenerRegistered = false;

  /** Override in subclass to return the WebF module name (e.g. 'Ble'). */
  protected abstract get moduleName(): string;

  constructor() {
    this._ensureRegistered();
  }

  /**
   * Remove the WebF module listener and clear all handlers.
   * Call when the bus is no longer needed (JS/TS has no destructors).
   * After dispose(), addListener() will re-register if called again.
   */
  dispose(): void {
    if (this.listenerRegistered) {
      const w = getWebf();
      w?.removeWebfModuleListener?.(this.moduleName);
      this.listenerRegistered = false;
    }
    this.handlers.clear();
  }

  /** Enables `using bus = new WebfModuleEventBus(...)` (Symbol.dispose). */
  [Symbol.dispose](): void {
    this.dispose();
  }

  protected _ensureRegistered(): void {
    if (this.listenerRegistered) return;
    const w = getWebf();
    if (!w?.addWebfModuleListener) return;
    this.listenerRegistered = true;
    w.addWebfModuleListener(this.moduleName, (event: Event, _extra: unknown) => {
      const e = event as { type?: string; detail?: unknown };
      const set = this.handlers.get(e.type ?? '');
      if (set) for (const h of set) h(e.detail);
    });
  }

  addListener<K extends EventType>(
    eventType: K,
    handler: (data: PayloadMap[K]) => void
  ): () => void {
    this._ensureRegistered();
    const w = getWebf();
    if (!w?.addWebfModuleListener) return () => {};

    let set = this.handlers.get(eventType);
    if (!set) {
      set = new Set();
      this.handlers.set(eventType, set);
    }
    const wrapped = (detail: unknown) => handler(detail as PayloadMap[K]);
    set.add(wrapped);
    return () => {
      set!.delete(wrapped);
      if (set!.size === 0) this.handlers.delete(eventType);
      if (this.handlers.size === 0 && this.listenerRegistered) {
        const w = getWebf();
        w?.removeWebfModuleListener?.(this.moduleName);
        this.listenerRegistered = false;
      }
    };
  }
}

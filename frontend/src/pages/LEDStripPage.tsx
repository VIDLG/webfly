import { useNavigate } from '@openwebf/react-router';
import { useQuery } from '@tanstack/react-query';
import { useLedSettings } from '../hooks/useLedSettings';

interface LedEffectManifest {
  id: string
  name: string
  description: string
}

async function fetchEffectList(): Promise<LedEffectManifest[]> {
  const base = import.meta.env.BASE_URL;
  const res = await fetch(`${base}effects/manifest.json`);
  if (!res.ok) throw new Error('Failed to load effects manifest');
  const { effects: ids }: { effects: string[] } = await res.json();

  return Promise.all(
    ids.map(async (id) => {
      const r = await fetch(`${base}effects/${id}/meta.json`);
      if (!r.ok) throw new Error(`Failed to load meta.json for effect "${id}"`);
      const meta: { id?: string; name: string; description: string } = await r.json();
      return { id: meta.id ?? id, name: meta.name, description: meta.description };
    }),
  );
}

export default function LEDStripPage() {
  const { navigate } = useNavigate();
  const enableTypeCheck = useLedSettings((s) => s.enableTypeCheck);
  const updateSettings = useLedSettings((s) => s.update);

  const { data: effects = [], isLoading, error } = useQuery({
    queryKey: ['effects', 'list'],
    queryFn: fetchEffectList,
  });

  return (
    <div className="min-h-screen bg-slate-50 px-6 py-6 text-slate-900 dark:bg-slate-950 dark:text-slate-100">
      <div className="mx-auto max-w-5xl">
        {/* 标题 */}
        <header className="mb-6 text-center">
          <h1 className="mb-2 text-4xl font-bold text-slate-900 dark:text-slate-100">
            LED Strip Control Center
          </h1>
          <p className="text-lg text-slate-600 dark:text-slate-400">
            Dynamically load and preview different LED strip effects
          </p>
        </header>

        {/* 特效选择器 */}
        <div className="rounded-2xl border border-slate-200 bg-white p-8 dark:border-slate-800 dark:bg-slate-900/60">
          <h2 className="mb-5 text-2xl font-bold text-slate-900 dark:text-slate-100">Choose an Effect</h2>

          {isLoading ? (
            <div className="text-center py-10 text-slate-600 dark:text-slate-400">
              <div className="inline-block w-10 h-10 rounded-full border-4 border-slate-300 border-t-sky-500 animate-spin dark:border-slate-700 dark:border-t-sky-400" />
              <p className="mt-4 text-base">Loading effects...</p>
            </div>
          ) : error ? (
            <div className="p-5 bg-red-900/20 border-2 border-red-500/50 rounded-lg text-red-200">
              <p className="font-mono text-sm whitespace-pre-wrap break-words">{error instanceof Error ? error.message : String(error)}</p>
            </div>
          ) : effects.length === 0 ? (
            <p className="text-center text-slate-500 dark:text-slate-400">No effects found.</p>
          ) : (
            <div className="flex flex-col gap-3">
              {effects.map((effect) => (
                <button
                  key={effect.id}
                  onClick={() => navigate(`/led/${effect.id}`)}
                  className="w-full rounded-xl border-2 border-slate-300 bg-white/70 px-5 py-4 text-left transition hover:opacity-95 active:scale-[0.98] focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-sky-400/40 dark:border-slate-700 dark:bg-slate-900/60"
                >
                  <span className="text-lg font-semibold text-slate-900 dark:text-slate-100">{effect.name}</span>
                  <p className="mt-1 text-sm text-slate-500 dark:text-slate-400">{effect.description}</p>
                </button>
              ))}
            </div>
          )}
        </div>

        {/* Settings */}
        <div className="mt-6 rounded-2xl border border-slate-200 bg-white p-8 dark:border-slate-800 dark:bg-slate-900/60">
          <h2 className="mb-4 text-2xl font-bold text-slate-900 dark:text-slate-100">Settings</h2>
          <label className="flex items-center justify-between gap-3 cursor-pointer">
            <div>
              <span className="text-sm font-medium text-slate-900 dark:text-slate-100">Type Checking</span>
              <p className="text-xs text-slate-500 dark:text-slate-400">
                Run TypeScript type checking on dynamic effect code before execution
              </p>
            </div>
            <button
              role="switch"
              aria-checked={enableTypeCheck}
              onClick={() => updateSettings({ enableTypeCheck: !enableTypeCheck })}
              className={
                'relative inline-flex h-6 w-11 shrink-0 items-center rounded-full transition-colors ' +
                (enableTypeCheck ? 'bg-sky-500' : 'bg-slate-300 dark:bg-slate-600')
              }
            >
              <span
                className={
                  'inline-block h-4 w-4 rounded-full bg-white transition-transform ' +
                  (enableTypeCheck ? 'translate-x-6' : 'translate-x-1')
                }
              />
            </button>
          </label>
        </div>
      </div>
    </div>
  );
}

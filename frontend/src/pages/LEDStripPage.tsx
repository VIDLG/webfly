import { useNavigate } from '@openwebf/react-router';
import { LED_EFFECTS } from '../led/effectsRegistry';

export default function LEDStripPage() {
  const { navigate } = useNavigate();

  return (
    <div className="min-h-screen bg-slate-50 px-6 py-6 text-slate-900 dark:bg-slate-950 dark:text-slate-100">
      <div className="mx-auto max-w-5xl">
        {/* 标题 */}
        <header className="mb-6 text-center">
          <h1 className="mb-2 text-4xl font-bold text-slate-900 dark:text-slate-100">
            💡 LED Strip Control Center
          </h1>
          <p className="text-lg text-slate-600 dark:text-slate-400">
            Dynamically load and preview different LED strip effects
          </p>
        </header>

        {/* 特效选择器 */}
        <div className="rounded-2xl border border-slate-200 bg-white p-8 dark:border-slate-800 dark:bg-slate-900/60">
          <h2 className="mb-5 text-2xl font-bold text-slate-900 dark:text-slate-100">Choose an Effect</h2>

          <div className="flex flex-col gap-3">
            {LED_EFFECTS.map((effect) => (
              <button
                key={effect.id}
                onClick={() => navigate(`/led/${effect.id}`)}
                className="w-full rounded-xl border-2 border-slate-300 bg-white/70 px-5 py-4 text-left text-lg font-semibold text-slate-900 transition hover:opacity-95 active:scale-[0.98] focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-sky-400/40 dark:border-slate-700 dark:bg-slate-900/60 dark:text-slate-100"
              >
                {effect.name}
              </button>
            ))}
          </div>
        </div>
      </div>
    </div>
  );
}

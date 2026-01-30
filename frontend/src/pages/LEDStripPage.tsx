import { useNavigate } from '@openwebf/react-router';
import { LED_EFFECTS } from '../led/effectsRegistry';

export default function LEDStripPage() {
  const { navigate } = useNavigate();

  return (
    <div className="min-h-screen bg-slate-950 py-6 px-6">
      <div className="mx-auto max-w-5xl">
        {/* 标题 */}
        <header className="mb-6 text-center">
          <h1 className="mb-2 text-4xl font-bold text-white">
            💡 LED Strip Control Center
          </h1>
          <p className="text-lg text-slate-300">
            Dynamically load and preview different LED strip effects
          </p>
        </header>

        {/* 特效选择器 */}
        <div className="rounded-2xl border border-slate-800 bg-slate-900/60 p-8">
          <h2 className="mb-5 text-2xl font-bold text-white">Choose an Effect</h2>

          <div className="flex flex-col gap-3">
            {LED_EFFECTS.map((effect) => (
              <button
                key={effect.id}
                onClick={() => navigate(`/led/${effect.id}`)}
                className="w-full rounded-xl border-2 border-slate-700 bg-slate-800 px-5 py-4 text-left text-lg font-semibold text-white transition hover:border-slate-600 hover:bg-slate-700 active:scale-[0.98] focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-slate-500"
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

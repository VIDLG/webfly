import { useNavigate } from '@openwebf/react-router';
import { LED_EFFECTS } from '../led/effectsRegistry';

export default function LEDStripPage() {
  const { navigate } = useNavigate();

  return (
    <div className="h-screen overflow-y-auto bg-slate-950 py-6 px-5">
      <div className="max-w-6xl mx-auto">
        {/* 标题 */}
        <div className="text-center mb-6 text-white">
          <h1 className="text-3xl sm:text-4xl font-bold mb-2 leading-tight">
            💡 LED Strip Control Center
          </h1>
          <p className="text-base sm:text-lg opacity-80 text-gray-300">
            Dynamically load and preview different LED strip effects
          </p>
        </div>

        {/* 特效选择器 */}
        <div className="rounded-2xl p-8 mb-8 bg-slate-900 ring-1 ring-slate-800">
          <h2 className="mb-5 text-gray-100 text-2xl font-bold">
            Choose an Effect
          </h2>
          
          <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-4">
            {LED_EFFECTS.map(effect => (
              <button
                key={effect.id}
                onClick={() => navigate(`/led/${effect.id}`)}
                className="p-5 rounded-xl text-left transition-all duration-300 border-2 border-slate-700 bg-slate-800 hover:border-indigo-500 hover:bg-slate-700 hover:scale-105 shadow-md group"
              >
                <div className="text-2xl mb-2 font-bold text-gray-100 group-hover:text-white">
                  {effect.name}
                </div>
                <div className="text-sm text-gray-400 leading-relaxed group-hover:text-gray-300">
                  {effect.description}
                </div>
              </button>
            ))}
          </div>
        </div>
      </div>
    </div>
  );
}

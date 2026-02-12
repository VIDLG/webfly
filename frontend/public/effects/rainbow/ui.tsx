const { FlutterCupertinoSlider } = CupertinoComponents;

export default function RainbowEffect(props: { deviceConfig?: DeviceConfig; onTick?: OnTickCallback }) {
  const { deviceConfig, onTick } = props;
  const ledCount = deviceConfig ? deviceConfig.strips.reduce((sum, s) => sum + s.ledCount, 0) : 20;
  const dark = useDarkMode();
  const { machine, speed, isIdle, isPaused, handleStart, handlePauseResume, handleStop, handleSpeedChange } =
    useEffectMachine({ ledCount }, onTick);

  const [hueStep, setHueStep] = React.useState(10);
  const [hueSpread, setHueSpread] = React.useState(18);
  const [saturation, setSaturation] = React.useState(100);
  const [brightness, setBrightness] = React.useState(100);

  const accent = dark ? '#818cf8' : '#6366f1';

  return (
    <div className="flex flex-col h-full min-h-[500px] font-sans text-slate-900 dark:text-slate-100">
      {!deviceConfig && (
        <div className="flex-1 flex items-center justify-center bg-white/70 p-8 dark:bg-slate-900/60">
          <div className="flex flex-wrap justify-center gap-3 max-w-2xl">
            {Array.from({length: machine.ledCount}, (_, i) => {
              const o = i * 3;
              const r = machine.leds[o], g = machine.leds[o + 1], b = machine.leds[o + 2];
              const lit = r > 0 || g > 0 || b > 0;
              return (
                <div
                  key={i}
                  className="w-8 h-8 sm:w-10 sm:h-10 rounded-full border-2 border-slate-300 bg-white/70 transition-colors duration-200 dark:border-slate-700 dark:bg-slate-900/60"
                  style={{
                    backgroundColor: lit ? `rgb(${r},${g},${b})` : undefined,
                    borderColor: lit ? `rgba(${r},${g},${b},0.5)` : undefined,
                    boxShadow: lit ? `0 0 20px rgba(${r},${g},${b},0.6)` : 'none',
                  }}
                />
              );
            })}
          </div>
        </div>
      )}

      <div className="space-y-4 border-t border-slate-200 bg-white p-6 dark:border-slate-800 dark:bg-slate-900/60">
        <div className="rounded-xl border border-slate-200 bg-white/70 p-4 dark:border-slate-800 dark:bg-slate-900/60 space-y-4">
          <div>
            <div className="flex justify-between items-center mb-2">
              <label className="text-sm font-bold text-slate-600 dark:text-slate-400">Hue Step</label>
              <span className="rounded-md border border-slate-300 bg-white px-3 py-1 font-mono text-xs text-indigo-500 dark:border-slate-700 dark:bg-slate-900/60">
                {hueStep}°
              </span>
            </div>
            <FlutterCupertinoSlider
              min={1} max={30} value={hueStep}
              onChange={(e: any) => { setHueStep(e.detail); machine.setConfig('hueStep', e.detail); }}
              activeColor={accent}
            />
          </div>

          <div>
            <div className="flex justify-between items-center mb-2">
              <label className="text-sm font-bold text-slate-600 dark:text-slate-400">Hue Spread</label>
              <span className="rounded-md border border-slate-300 bg-white px-3 py-1 font-mono text-xs text-indigo-500 dark:border-slate-700 dark:bg-slate-900/60">
                {hueSpread}°
              </span>
            </div>
            <FlutterCupertinoSlider
              min={1} max={36} value={hueSpread}
              onChange={(e: any) => { setHueSpread(e.detail); machine.setConfig('hueSpread', e.detail); }}
              activeColor={accent}
            />
          </div>

          <div>
            <div className="flex justify-between items-center mb-2">
              <label className="text-sm font-bold text-slate-600 dark:text-slate-400">Saturation</label>
              <span className="rounded-md border border-slate-300 bg-white px-3 py-1 font-mono text-xs text-indigo-500 dark:border-slate-700 dark:bg-slate-900/60">
                {saturation}%
              </span>
            </div>
            <FlutterCupertinoSlider
              min={0} max={100} value={saturation}
              onChange={(e: any) => { setSaturation(e.detail); machine.setConfig('saturation', e.detail / 100); }}
              activeColor={accent}
            />
          </div>

          <div>
            <div className="flex justify-between items-center mb-2">
              <label className="text-sm font-bold text-slate-600 dark:text-slate-400">Brightness</label>
              <span className="rounded-md border border-slate-300 bg-white px-3 py-1 font-mono text-xs text-indigo-500 dark:border-slate-700 dark:bg-slate-900/60">
                {brightness}%
              </span>
            </div>
            <FlutterCupertinoSlider
              min={0} max={100} value={brightness}
              onChange={(e: any) => { setBrightness(e.detail); machine.setConfig('brightness', e.detail / 100); }}
              activeColor={accent}
            />
          </div>
        </div>

        <div className="rounded-xl border border-slate-200 bg-white/70 p-4 dark:border-slate-800 dark:bg-slate-900/60">
          <div className="flex justify-between items-center mb-3">
            <label className="text-sm font-bold text-slate-600 dark:text-slate-400">Speed</label>
            <span className="rounded-md border border-slate-300 bg-white px-3 py-1 font-mono text-xs text-indigo-500 dark:border-slate-700 dark:bg-slate-900/60">
              {speed}ms
            </span>
          </div>
          <FlutterCupertinoSlider
            min={20} max={300} value={speed}
            onChange={(e: any) => handleSpeedChange(e.detail)}
            activeColor={accent}
          />
          <div className="flex justify-between text-[11px] text-slate-600 dark:text-slate-400 font-medium px-1 mt-2 uppercase tracking-wide">
            <span>Fast</span><span>Slow</span>
          </div>
        </div>

        <div className="flex items-center justify-center gap-3">
          <div className="flex-1">
            <button
              onClick={isIdle ? handleStart : handleStop}
              className="w-full rounded-xl py-3 text-center text-sm font-semibold text-white transition-colors active:opacity-80"
              style={{ backgroundColor: isIdle ? (dark ? '#34d399' : '#10b981') : (dark ? '#f87171' : '#ef4444') }}>
              {isIdle ? 'Start' : 'Stop'}
            </button>
          </div>
          <div className="flex-1">
            <button
              onClick={handlePauseResume} disabled={isIdle}
              className="w-full rounded-xl py-3 text-center text-sm font-semibold text-white transition-colors active:opacity-80"
              style={{ backgroundColor: isIdle ? (dark ? '#475569' : '#94a3b8') : (isPaused ? (dark ? '#fbbf24' : '#f59e0b') : (dark ? '#60a5fa' : '#3b82f6')), opacity: isIdle ? 0.4 : 1 }}>
              {isPaused ? 'Resume' : 'Pause'}
            </button>
          </div>
        </div>
      </div>
    </div>
  );
}

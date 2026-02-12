const { FlutterCupertinoSlider } = CupertinoComponents;

export default function ChaseEffect(props: { deviceConfig?: DeviceConfig; onTick?: OnTickCallback }) {
  const { deviceConfig, onTick } = props;
  const ledCount = deviceConfig ? deviceConfig.strips.reduce((sum, s) => sum + s.ledCount, 0) : 20;
  const dark = useDarkMode();
  const { machine, speed, isIdle, isPaused, handleStart, handlePauseResume, handleStop, handleSpeedChange } =
    useEffectMachine({ ledCount }, onTick);

  const [hue, setHue] = React.useState(43);
  const [sat, setSat] = React.useState(85);
  const [val, setVal] = React.useState(98);
  const [chaseCount, setChaseCount] = React.useState(2);

  const handleHue = (h: number) => {
    setHue(h);
    machine.setConfig('color', { mode: 'hsv', h, s: sat / 100, v: val / 100 });
  };
  const handleSat = (s: number) => {
    setSat(s);
    machine.setConfig('color', { mode: 'hsv', h: hue, s: s / 100, v: val / 100 });
  };
  const handleVal = (v: number) => {
    setVal(v);
    machine.setConfig('color', { mode: 'hsv', h: hue, s: sat / 100, v: v / 100 });
  };

  const handleChaseCountChange = (v: number) => {
    setChaseCount(v);
    machine.setConfig('chaseCount', v);
  };

  const previewRgb = hsvToRgb(hue, sat / 100, val / 100);
  const previewColor = `rgb(${previewRgb[0]},${previewRgb[1]},${previewRgb[2]})`;
  const accent = dark ? '#fbbf24' : '#f59e0b';

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
                  className="w-8 h-8 sm:w-10 sm:h-10 rounded-full border-2 border-slate-300 bg-white/70 transition-colors duration-150 dark:border-slate-700 dark:bg-slate-900/60"
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
          <div className="flex items-center gap-3 mb-1">
            <div className="w-8 h-8 rounded-full border-2 border-slate-300 dark:border-slate-600" style={{ backgroundColor: previewColor }} />
            <label className="text-sm font-bold text-slate-600 dark:text-slate-400">Color</label>
          </div>
          <div>
            <div className="flex justify-between items-center mb-2">
              <label className="text-sm font-bold text-slate-600 dark:text-slate-400">Hue</label>
              <span className="rounded-md border border-slate-300 bg-white px-3 py-1 font-mono text-xs text-amber-500 dark:border-slate-700 dark:bg-slate-900/60">
                {hue}°
              </span>
            </div>
            <FlutterCupertinoSlider
              min={0} max={360} value={hue}
              onChange={(e: any) => handleHue(e.detail)}
              activeColor={previewColor}
            />
          </div>
          <div>
            <div className="flex justify-between items-center mb-2">
              <label className="text-sm font-bold text-slate-600 dark:text-slate-400">Saturation</label>
              <span className="rounded-md border border-slate-300 bg-white px-3 py-1 font-mono text-xs text-amber-500 dark:border-slate-700 dark:bg-slate-900/60">
                {sat}%
              </span>
            </div>
            <FlutterCupertinoSlider
              min={0} max={100} value={sat}
              onChange={(e: any) => handleSat(e.detail)}
              activeColor={previewColor}
            />
          </div>
          <div>
            <div className="flex justify-between items-center mb-2">
              <label className="text-sm font-bold text-slate-600 dark:text-slate-400">Brightness</label>
              <span className="rounded-md border border-slate-300 bg-white px-3 py-1 font-mono text-xs text-amber-500 dark:border-slate-700 dark:bg-slate-900/60">
                {val}%
              </span>
            </div>
            <FlutterCupertinoSlider
              min={0} max={100} value={val}
              onChange={(e: any) => handleVal(e.detail)}
              activeColor={previewColor}
            />
          </div>
        </div>

        <div className="rounded-xl border border-slate-200 bg-white/70 p-4 dark:border-slate-800 dark:bg-slate-900/60">
          <div className="flex justify-between items-center mb-3">
            <label className="text-sm font-bold text-slate-600 dark:text-slate-400">Chase Points</label>
            <span className="rounded-md border border-slate-300 bg-white px-3 py-1 font-mono text-xs text-amber-500 dark:border-slate-700 dark:bg-slate-900/60">
              {chaseCount}
            </span>
          </div>
          <FlutterCupertinoSlider
            min={1} max={5} value={chaseCount}
            onChange={(e: any) => handleChaseCountChange(e.detail)}
            activeColor={accent}
          />
        </div>

        <div className="rounded-xl border border-slate-200 bg-white/70 p-4 dark:border-slate-800 dark:bg-slate-900/60">
          <div className="flex justify-between items-center mb-3">
            <label className="text-sm font-bold text-slate-600 dark:text-slate-400">Speed</label>
            <span className="rounded-md border border-slate-300 bg-white px-3 py-1 font-mono text-xs text-amber-500 dark:border-slate-700 dark:bg-slate-900/60">
              {speed}ms
            </span>
          </div>
          <FlutterCupertinoSlider
            min={30} max={300} value={speed}
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

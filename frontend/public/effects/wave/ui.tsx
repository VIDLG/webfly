// @ts-expect-error: WebF interop
const { FlutterCupertinoButton, FlutterCupertinoSlider } = CupertinoComponents;

export default function WaveEffect() {
  // @ts-expect-error: WebF interop
  const { leds, speed, setSpeed, handleStart, handlePauseResume, handleStop, isIdle, isPaused } = useWaveEffect();

  return (
    <div className="flex flex-col h-full min-h-[500px] text-gray-100 font-sans">
      <div className="flex-1 flex items-center justify-center p-8 bg-slate-900/50">
        <div className="flex flex-wrap justify-center gap-3 max-w-2xl">
          {leds.map((isOn: boolean, index: number) => (
            <div
              key={index}
              className={`w-8 h-8 sm:w-10 sm:h-10 rounded-full border-2 border-slate-700 transition-colors duration-200 ${
                isOn
                  ? 'bg-emerald-400 shadow-[0_0_20px_rgba(16,185,129,0.8)] border-emerald-300'
                  : 'bg-slate-800'
              }`}
            />
          ))}
        </div>
      </div>

      <div className="p-6 bg-slate-800/50 border-t border-slate-700 space-y-6">
        {/* Speed Control Panel */}
        <div className="bg-slate-900/50 p-4 rounded-xl border border-slate-700/50">
          <div className="flex justify-between items-center mb-3">
            <label className="text-sm font-bold text-slate-300 flex items-center gap-2">
              <span className="text-lg">🚀</span> Speed Control
            </label>
            <span className="font-mono bg-slate-800 text-emerald-400 px-3 py-1 rounded-md text-xs border border-slate-700">
              {speed}ms
            </span>
          </div>
          <FlutterCupertinoSlider
            min={50}
            max={500}
            step={50}
            value={speed}
            // @ts-expect-error: WebF interop
            onChange={(e) => setSpeed(e.detail)}
            activeColor="#10b981" // emerald-500
          />
          <div className="flex justify-between text-[11px] text-slate-500 font-medium px-1 mt-2 uppercase tracking-wide">
            <span>Fast</span>
            <span>Slow</span>
          </div>
        </div>

        {/* Playback Controls */}
        <div className="flex items-center justify-center gap-3">
          {/* Start Button */}
          <div className="flex-1">
            <FlutterCupertinoButton
              onClick={handleStart}
              disabled={!isIdle}
              variant="filled"
              style={{ 
                width: '100%', 
                backgroundColor: isIdle ? '#10b981' : undefined // emerald-500
              }}
            >
              <span className="text-xl mr-2">▶</span> Start
            </FlutterCupertinoButton>
          </div>

          {/* Pause/Resume Button */}
          <div className="flex-1">
            <FlutterCupertinoButton
              onClick={handlePauseResume}
              disabled={isIdle}
              variant="filled"
              style={{
                width: '100%',
                backgroundColor: isIdle ? undefined : (isPaused ? '#f59e0b' : '#3b82f6') // amber-500 : blue-500
              }}
            >
              <span className="text-xl mr-2">{isPaused ? '▶' : '⏸'}</span>
              {isPaused ? 'Resume' : 'Pause'}
            </FlutterCupertinoButton>
          </div>

          {/* Stop Button */}
          <div className="flex-1">
            <FlutterCupertinoButton
              onClick={handleStop}
              disabled={isIdle}
              variant="filled"
              style={{
                width: '100%',
                backgroundColor: isIdle ? undefined : '#ef4444' // red-500
              }}
            >
              <span className="text-xl mr-2">⏹</span> Stop
            </FlutterCupertinoButton>
          </div>
        </div>
      </div>
    </div>
  );
}
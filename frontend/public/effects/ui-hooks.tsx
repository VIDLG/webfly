/**
 * Shared React hooks for LED effect UI components.
 *
 * Depends on: React (global), createEffect (from effect.js)
 */

/** Reactively tracks dark mode via the host app's theme system. */
function useDarkMode(): boolean {
  return useTheme().theme === 'dark';
}

interface UseEffectMachineResult {
  machine: EffectMachine
  speed: number
  isIdle: boolean
  isPaused: boolean
  handleStart(): void
  handlePauseResume(): void
  handleStop(): void
  handleSpeedChange(ms: number): void
}

function useEffectMachine(config?: EffectBaseConfig, onTick?: OnTickCallback): UseEffectMachineResult {
  const machineRef = React.useRef<EffectMachine | null>(null);
  if (!machineRef.current) machineRef.current = createEffect(config);
  const machine = machineRef.current!;

  const onTickRef = React.useRef<OnTickCallback | undefined>(onTick);
  onTickRef.current = onTick;

  const [, setFrame] = React.useState(0);
  const rerender = () => setFrame((n: number) => n + 1);

  const [speed, setSpeed] = React.useState(machine.speed);
  const intervalRef = React.useRef<number | null>(null);

  const clearTimer = () => {
    if (intervalRef.current !== null) {
      clearInterval(intervalRef.current);
      intervalRef.current = null;
    }
  };

  const startTimer = () => {
    clearTimer();
    intervalRef.current = window.setInterval(() => {
      machine.tick();
      if (onTickRef.current) onTickRef.current(machine.leds);
      rerender();
    }, machine.speed);
  };

  React.useEffect(() => clearTimer, []);

  const handleSpeedChange = (ms: number) => {
    setSpeed(ms);
    machine.setSpeed(ms);
    if (machine.status === 'running') startTimer();
  };

  const handleStart = () => { machine.start(); startTimer(); rerender(); };
  const handlePauseResume = () => {
    if (machine.status === 'running') { machine.pause(); clearTimer(); }
    else if (machine.status === 'paused') { machine.resume(); startTimer(); }
    rerender();
  };
  const handleStop = () => { machine.stop(); clearTimer(); rerender(); };

  return {
    machine,
    speed,
    isIdle: machine.status === 'idle',
    isPaused: machine.status === 'paused',
    handleStart,
    handlePauseResume,
    handleStop,
    handleSpeedChange,
  };
}

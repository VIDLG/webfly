// eslint-disable-next-line @typescript-eslint/no-unused-vars
function useBlinkEffect() {
  const [status, setStatus] = React.useState<'idle' | 'running' | 'paused'>('idle');
  const [speed, setSpeed] = React.useState(200);
  const [leds, setLeds] = React.useState(Array(20).fill(false));
  const intervalRef = React.useRef<number | null>(null);
  const stateRef = React.useRef(true);

  const tick = React.useCallback(() => {
    setLeds(Array(20).fill(stateRef.current));
    stateRef.current = !stateRef.current;
  }, []);

  const handleStart = () => {
    if (status === 'idle') {
      if (intervalRef.current) clearInterval(intervalRef.current);
      intervalRef.current = window.setInterval(tick, speed);
      setStatus('running');
    }
  };

  const handlePauseResume = () => {
    if (status === 'running') {
      if (intervalRef.current) {
        clearInterval(intervalRef.current);
        intervalRef.current = null;
      }
      setStatus('paused');
    } else if (status === 'paused') {
      if (intervalRef.current) clearInterval(intervalRef.current);
      intervalRef.current = window.setInterval(tick, speed);
      setStatus('running');
    }
  };

  const handleStop = () => {
    if (intervalRef.current) {
      clearInterval(intervalRef.current);
      intervalRef.current = null;
    }
    setLeds(Array(20).fill(false));
    stateRef.current = true;
    setStatus('idle');
  };

  React.useEffect(() => {
    return () => {
      if (intervalRef.current) {
        clearInterval(intervalRef.current);
      }
    };
  }, []);

  React.useEffect(() => {
    if (status === 'running') {
      if (intervalRef.current) clearInterval(intervalRef.current);
      intervalRef.current = window.setInterval(tick, speed);
    }
  }, [speed, status, tick]);

  const isIdle = status === 'idle';
  const isRunning = status === 'running';
  const isPaused = status === 'paused';

  return {
    leds,
    speed,
    setSpeed,
    status,
    handleStart,
    handlePauseResume,
    handleStop,
    isIdle,
    isRunning,
    isPaused
  };
}
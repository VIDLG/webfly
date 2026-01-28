// eslint-disable-next-line @typescript-eslint/no-unused-vars
function useChaseEffect() {
  const [status, setStatus] = React.useState<'idle' | 'running' | 'paused'>('idle');
  const [speed, setSpeed] = React.useState(80);
  const [leds, setLeds] = React.useState(Array(20).fill(false));
  const intervalRef = React.useRef<number | null>(null);
  const positionRef = React.useRef(0);

  const tick = React.useCallback(() => {
    const pos = positionRef.current;
    const newLeds = Array(20).fill(false);
    newLeds[pos] = true;
    newLeds[(pos + 10) % 20] = true; // Two LEDs chasing
    setLeds(newLeds);
    positionRef.current = (pos + 1) % 20;
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
    positionRef.current = 0;
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

  return { leds, speed, setSpeed, status, handleStart, handlePauseResume, handleStop, isIdle, isRunning, isPaused };
}
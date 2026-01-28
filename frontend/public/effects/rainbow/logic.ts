// eslint-disable-next-line @typescript-eslint/no-unused-vars
function useRainbowEffect() {
  function hslToRgb(h: number, s: number, l: number) {
    const c = (1 - Math.abs(2 * l - 1)) * s;
    const x = c * (1 - Math.abs(((h / 60) % 2) - 1));
    const m = l - c / 2;
    let r = 0,
      g = 0,
      b = 0;

    if (h < 60) {
      r = c;
      g = x;
      b = 0;
    } else if (h < 120) {
      r = x;
      g = c;
      b = 0;
    } else if (h < 180) {
      r = 0;
      g = c;
      b = x;
    } else if (h < 240) {
      r = 0;
      g = x;
      b = c;
    } else if (h < 300) {
      r = x;
      g = 0;
      b = c;
    } else {
      r = c;
      g = 0;
      b = x;
    }

    return {
      r: Math.round((r + m) * 255),
      g: Math.round((g + m) * 255),
      b: Math.round((b + m) * 255),
    };
  }

  const [status, setStatus] = React.useState<'idle' | 'running' | 'paused'>('idle');
  const [speed, setSpeed] = React.useState(100);
  const [leds, setLeds] = React.useState(Array(20).fill({ r: 0, g: 0, b: 0 }));
  const intervalRef = React.useRef<number | null>(null);
  const offsetRef = React.useRef(0);

  const tick = React.useCallback(() => {
    const offset = offsetRef.current;
    
    setLeds(
      Array(20)
        .fill(0)
        .map((_, index) => {
          const hue = (index * 18 + offset) % 360;
          return hslToRgb(hue, 1, 0.5);
        }),
    );
    offsetRef.current = (offset + 10) % 360;
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
    setLeds(Array(20).fill({ r: 0, g: 0, b: 0 }));
    offsetRef.current = 0;
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
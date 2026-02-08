import React, { useState, useEffect, useRef } from 'react';
import { useNavigate } from '@openwebf/react-router';
import {
  getAdapterState as getBleAdapterState,
  getScanResults,
  isSupported as isBleSupported,
  startScan as startBleScan,
  stopScan as stopBleScan,
  type ScanResult,
} from '@webfly/ble';
import { useBleEventLog, useBleConnectedDeviceIds } from '../hooks/useBle';

const BleDemoPage: React.FC = () => {
  const { navigate } = useNavigate();
  const [isSupported, setIsSupported] = useState<boolean | null>(null);
  const [isScanning, setIsScanning] = useState(false);
  const [results, setResults] = useState<ScanResult[]>([]);
  const [error, setError] = useState<string | null>(null);
  const intervalRef = useRef<number | null>(null);
  const [adapterState, setAdapterState] = useState<string>('checking...');

  const { logs: eventLogs, pushLog } = useBleEventLog(50);
  const connectedDeviceIds = useBleConnectedDeviceIds();

  useEffect(() => {
    checkSupport();
    getAdapterState();
    return () => {
      stopScan();
    };
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, []);

  const getAdapterState = async () => {
    try {
      const res = await getBleAdapterState();
      if (res.isErr()) {
        setAdapterState(`Error: ${res.error}`);
      } else {
        setAdapterState(res.value ?? 'unknown');
      }
    } catch (e: unknown) {
      console.error('getAdapterState failed:', e);
      const msg = e instanceof Error ? e.message : String(e);
      setAdapterState(`Error: ${msg || 'Unknown'}`);
    }
  };

  const checkSupport = async () => {
    try {
      console.log('Checking WebF BLE support...');
      try {
        const res = await isBleSupported();
        if (res.isErr()) {
            console.error('BLE support check error:', res.error);
            setIsSupported(false);
            setError(`BLE Error: ${res.error}`);
            return;
        }

        const supported = res.value === true;
        setIsSupported(supported);
        if (!supported) setError('BLE not supported on this device');
      } catch (err: unknown) {
        const message = err instanceof Error ? err.message : String(err);
        if (message && message.includes('WebF invokeModule is not available')) {
            setIsSupported(false);
            setError('WebF environment not detected.');
        } else {
            // Module might be missing or other error
             setIsSupported(false);
             setError(`BLE module error: ${message}`);
        }
      }
    } catch (e: unknown) {
      const msg = e instanceof Error ? e.message : String(e);
      setError(`Check support failed: ${msg}`);
    }
  };

  const clearResults = () => {
    setResults([]);
  };

  const updateResults = async () => {
    try {
      const res = await getScanResults();
      if (res.isErr()) {
           console.error('getScanResults error:', res.error);
           return;
      }

      const scanResults = Array.isArray(res.value) ? res.value : [];
      if (Array.isArray(scanResults)) {
        setResults((prev) => {
          const map = new Map<string, ScanResult>();
          prev.forEach(r => map.set(r.remoteId, r));
          scanResults.forEach((r: ScanResult) => map.set(r.remoteId, r));
          return Array.from(map.values()).sort((a,b) => b.rssi - a.rssi);
        });
      }
    } catch (e) {
      console.error(e);
    }
  };
  const handleScanToggle = async () => {
    if (isScanning) {
      await stopScan();
    } else {
      await startScan();
    }
  };

  const startScan = async () => {
    try {
      // Refresh adapter state before scanning
      getAdapterState();

      setError(null);
      setResults([]);
      // Start scanning
      // Pass arguments as positional args, invokeWebFModule handles spreading
      const res = await startBleScan({ timeout: 15 });
      if (res.isErr()) {
          throw new Error(res.error);
      }

      setIsScanning(true);
      pushLog('Scan started');

      // Poll for results every second
      // @ts-expect-error - setInterval return type mismatch in some envs
      intervalRef.current = setInterval(updateResults, 1000);
    } catch (e: unknown) {
      const msg = e instanceof Error ? e.message : String(e);
      setError(`Start scan failed: ${msg}`);
      setIsScanning(false);
    }
  };

  const stopScan = async () => {
    try {
      if (intervalRef.current) {
        clearInterval(intervalRef.current);
        intervalRef.current = null;
      }
      if (isScanning) {
        const res = await stopBleScan();
        if (res.isErr()) {
             console.error('stopScan error:', res.error);
        }
        pushLog('Scan stopped');
      }
      setIsScanning(false);
    } catch (e: unknown) {
      const msg = e instanceof Error ? e.message : String(e);
      setError(`Stop scan failed: ${msg}`);
    }
  };

  return (
    <div className="mx-auto flex min-h-screen max-w-5xl flex-col gap-8 px-6 py-6 bg-gray-50 dark:bg-gray-950">
      <header className="flex items-start gap-4">
        <button 
          onClick={() => navigate(-1)}
          className="group mt-1 flex h-10 w-10 items-center justify-center rounded-full border border-slate-200 bg-white shadow-sm transition-all hover:border-slate-300 hover:bg-slate-50 active:scale-95 dark:border-slate-800 dark:bg-slate-900 dark:hover:border-slate-700 dark:hover:bg-slate-800"
          aria-label="Go Back"
        >
          <svg 
            className="h-5 w-5 text-slate-700 transition group-hover:text-slate-900 dark:text-slate-300 dark:group-hover:text-white" 
            fill="none" viewBox="0 0 24 24" stroke="currentColor" strokeWidth="2.5"
          >
            <path strokeLinecap="round" strokeLinejoin="round" d="M15 19l-7-7 7-7" />
          </svg>
        </button>
        <div>
          <h1 className="text-2xl font-semibold text-slate-900 dark:text-slate-100">BLE Scanner</h1>
          <p className="mt-1 text-sm text-slate-600 dark:text-slate-400">
            Discover nearby Bluetooth Low Energy peripherals using native device capabilities.
          </p>
        </div>
      </header>

      <div className="flex flex-col gap-6">
        {error && (
          <div className="rounded-xl bg-red-50 p-4 text-sm text-red-700 border border-red-100 dark:bg-red-900/20 dark:border-red-900/30 dark:text-red-400">
            {error}
          </div>
        )}

        {/* Adapter Info Card */}
        <div className="rounded-2xl border border-slate-200 bg-white p-6 shadow-sm dark:border-slate-800 dark:bg-slate-900/60">
           <div className="flex items-center justify-between">
              <h2 className="text-lg font-semibold text-slate-900 dark:text-slate-100">Adapter Status</h2>
              <button onClick={getAdapterState} className="text-xs text-indigo-500 hover:underline" title="Refresh Status">Refresh</button>
           </div>
           
           <div className="mt-4 grid grid-cols-2 gap-4 sm:grid-cols-4">
              <div className="rounded-xl bg-slate-50 p-3 dark:bg-slate-800/50">
                  <div className="text-xs font-medium text-slate-500 uppercase tracking-wider">State</div>
                  <div className="mt-1 font-mono text-sm font-semibold text-slate-900 dark:text-slate-100 uppercase">{adapterState}</div>
              </div>
              <div className="rounded-xl bg-slate-50 p-3 dark:bg-slate-800/50">
                  <div className="text-xs font-medium text-slate-500 uppercase tracking-wider">Supported</div>
                  <div className="mt-1 font-mono text-sm font-semibold text-slate-900 dark:text-slate-100">
                      {isSupported === null ? '...' : (isSupported ? 'YES' : 'NO')}
                  </div>
              </div>
              <div className="rounded-xl bg-slate-50 p-3 dark:bg-slate-800/50">
                  <div className="text-xs font-medium text-slate-500 uppercase tracking-wider">Connected</div>
                  <div className="mt-1 font-mono text-sm font-semibold text-slate-900 dark:text-slate-100">
                      {connectedDeviceIds.length}
                  </div>
              </div>
           </div>
        </div>

        {/* BLE Events (useBleEventLog hook + pushLog for scan start/stop) */}
        <div className="rounded-2xl border border-slate-200 bg-white p-6 shadow-sm dark:border-slate-800 dark:bg-slate-900/60">
          <h2 className="text-lg font-semibold text-slate-900 dark:text-slate-100">BLE Events</h2>
          <p className="mt-1 text-sm text-slate-600 dark:text-slate-400">
            connectionStateChanged, characteristicReceived; Scan start/stop logged locally.
          </p>
          <div className="mt-4 max-h-48 overflow-y-auto rounded-xl bg-slate-900 px-3 py-2 font-mono text-xs text-slate-300">
            {eventLogs.length === 0 ? (
              <div className="text-slate-500">No events yet. Start scan or connect a device to see events.</div>
            ) : (
              eventLogs.map((line, i) => (
                <div key={i} className="break-all py-0.5">
                  {line}
                </div>
              ))
            )}
          </div>
        </div>

        {/* Connected devices (event-driven: connectionStateChanged) */}
        {connectedDeviceIds.length > 0 && (
          <div className="rounded-2xl border border-slate-200 bg-white p-6 shadow-sm dark:border-slate-800 dark:bg-slate-900/60">
            <h2 className="text-lg font-semibold text-slate-900 dark:text-slate-100">Connected Devices</h2>
            <p className="mt-1 text-sm text-slate-600 dark:text-slate-400">
              Updated from connectionStateChanged events (useBleConnectedDeviceIds)
            </p>
            <ul className="mt-4 space-y-2">
              {connectedDeviceIds.map((deviceId) => (
                <li
                  key={deviceId}
                  className="rounded-xl border border-slate-200 bg-slate-50 px-4 py-3 font-mono text-sm text-slate-800 dark:border-slate-700 dark:bg-slate-800/50 dark:text-slate-200"
                >
                  {deviceId}
                </li>
              ))}
            </ul>
          </div>
        )}

        {/* Controls */}
        <div className="flex flex-wrap items-center justify-between gap-3">
          <div className="flex gap-3">
             <button
               onClick={handleScanToggle}
               disabled={!isSupported}
               className={`rounded-full px-4 py-2 text-xs font-semibold text-white shadow-sm transition-all active:scale-[0.98] focus-visible:outline-none focus-visible:ring-2 
                 ${!isSupported 
                   ? 'bg-slate-300 cursor-not-allowed dark:bg-slate-700' 
                   : isScanning
                     ? 'bg-red-500 hover:bg-red-600 focus-visible:ring-red-400/70'
                     : 'bg-gradient-to-r from-indigo-500 to-purple-600 hover:from-indigo-400 hover:to-purple-500 focus-visible:ring-purple-400/70'}`}
             >
               {isScanning ? 'Stop Scan' : 'Start Scan'}
             </button>

             <button
               onClick={clearResults}
               disabled={results.length === 0}
               className={`rounded-full px-4 py-2 text-xs font-semibold border border-slate-200 text-slate-600 transition-all hover:bg-slate-50 hover:text-slate-900 active:scale-[0.98] focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-slate-400/50 dark:border-slate-700 dark:text-slate-400 dark:hover:bg-slate-800 dark:hover:text-slate-200
                ${results.length === 0 ? 'opacity-50 cursor-not-allowed' : ''}`}
             >
               Clear
             </button>
           </div>
           
           <div className="flex items-center gap-2">
              <span className="flex h-6 min-w-[1.5rem] items-center justify-center rounded-full bg-slate-100 px-2 text-xs font-bold text-slate-900 dark:bg-slate-800 dark:text-slate-100">
                  {results.length}
              </span>
           </div>
        </div>

        {/* Results List */}
        <div className="space-y-3">
            {results.length === 0 && (
                <div className="rounded-2xl border border-dashed border-slate-300 p-12 text-center dark:border-slate-700">
                    <div className="text-slate-400 dark:text-slate-500">
                        {isScanning ? 'Scanning for nearby devices...' : 'No devices found. Start a scan to begin.'}
                    </div>
                </div>
            )}
            
          {results.map((res) => {
            const name = res.advertisementData.advName || 'Unknown Device';
            return (
              <div 
                key={res.remoteId}
                className="flex items-center justify-between rounded-xl border border-slate-200 bg-white p-4 shadow-sm transition hover:border-indigo-200 dark:border-slate-800 dark:bg-slate-900/60 dark:hover:border-indigo-500/30"
              >
                <div className="flex flex-col">
                  <span className="font-semibold text-slate-900 dark:text-slate-100">{name}</span>
                  <span className="font-mono text-xs text-slate-500">{res.remoteId}</span>
                </div>
                <div className="flex items-center gap-3">
                    <div className="rounded-lg bg-indigo-50 px-2 py-1 text-xs font-bold text-indigo-600 dark:bg-indigo-900/30 dark:text-indigo-400">
                        {res.rssi} dBm
                    </div>
                </div>
              </div>
            );
          })}
        </div>
      </div>
    </div>
  );
};

export default BleDemoPage;

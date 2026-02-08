import React, { useState, useEffect } from 'react';
import { useNavigate } from '@openwebf/react-router';
import {
  checkStatus,
  request,
  requestMultiple,
  openAppSettings,
  shouldShowRequestRationale,
  type PermissionName,
  type PermissionStatus,
} from '@webfly/permission';

const DEMO_PERMISSIONS: PermissionName[] = [
  'camera',
  'microphone',
  'location',
  'locationWhenInUse',
  'bluetooth',
  'bluetoothScan',
  'bluetoothConnect',
  'notification',
];

const PermissionDemoPage: React.FC = () => {
  const { navigate } = useNavigate();
  const [statuses, setStatuses] = useState<Record<string, PermissionStatus | string>>({});
  const [rationales, setRationales] = useState<Record<string, boolean>>({});
  const [error, setError] = useState<string | null>(null);
  const [loading, setLoading] = useState<string | null>(null);
  const [settingsOpened, setSettingsOpened] = useState<boolean | null>(null);

  useEffect(() => {
    setError(null);
  }, []);

  const handleCheck = async (permission: PermissionName) => {
    setLoading(permission);
    setError(null);
    try {
      const res = await checkStatus(permission);
      if (res.isErr()) {
        setStatuses((prev) => ({
          ...prev,
          [permission]: res.error ?? 'Error',
        }));
      } else {
        setStatuses((prev) => ({ ...prev, [permission]: res.value ?? 'unknown' }));
      }
    } catch (e: unknown) {
      const msg = e instanceof Error ? e.message : String(e);
      setError(`Check failed: ${msg}`);
      setStatuses((prev) => ({ ...prev, [permission]: `Error: ${msg}` }));
    } finally {
      setLoading(null);
    }
  };

  const handleRequest = async (permission: PermissionName) => {
    setLoading(permission);
    setError(null);
    try {
      const res = await request(permission);
      if (res.isErr()) {
        setStatuses((prev) => ({
          ...prev,
          [permission]: res.error ?? 'Error',
        }));
      } else {
        setStatuses((prev) => ({ ...prev, [permission]: res.value ?? 'unknown' }));
      }
    } catch (e: unknown) {
      const msg = e instanceof Error ? e.message : String(e);
      setError(`Request failed: ${msg}`);
      setStatuses((prev) => ({ ...prev, [permission]: `Error: ${msg}` }));
    } finally {
      setLoading(null);
    }
  };

  const handleCheckRationale = async (permission: PermissionName) => {
    setError(null);
    try {
      const res = await shouldShowRequestRationale(permission);
      if (res.isErr()) {
        setRationales((prev) => ({ ...prev, [permission]: false }));
      } else {
        setRationales((prev) => ({ ...prev, [permission]: res.value === true }));
      }
    } catch {
      setRationales((prev) => ({ ...prev, [permission]: false }));
    }
  };

  const handleRequestMultiple = async () => {
    const perms: PermissionName[] = ['camera', 'microphone'];
    setLoading('multiple');
    setError(null);
    try {
      const res = await requestMultiple(perms);
      if (res.isErr()) {
        setError(res.error ?? 'Request multiple failed');
      } else if (res.value && typeof res.value === 'object') {
        setStatuses((prev) => ({ ...prev, ...res.value }));
      }
    } catch (e: unknown) {
      const msg = e instanceof Error ? e.message : String(e);
      setError(`Request multiple failed: ${msg}`);
    } finally {
      setLoading(null);
    }
  };

  const handleOpenSettings = async () => {
    setError(null);
    setSettingsOpened(null);
    try {
      const res = await openAppSettings();
      if (res.isErr()) {
        setSettingsOpened(false);
        setError('Could not open app settings');
      } else {
        setSettingsOpened(res.value === true);
      }
    } catch (e: unknown) {
      const msg = e instanceof Error ? e.message : String(e);
      setSettingsOpened(false);
      setError(`Open settings failed: ${msg}`);
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
            className="h-5 w-5 text-slate-700 transition group-hover:text-slate-900 dark:text-slate-300 dark:text-slate-100"
            fill="none"
            viewBox="0 0 24 24"
            stroke="currentColor"
            strokeWidth="2.5"
          >
            <path strokeLinecap="round" strokeLinejoin="round" d="M15 19l-7-7 7-7" />
          </svg>
        </button>
        <div>
          <h1 className="text-2xl font-semibold text-slate-900 dark:text-slate-100">
            Permission Demo
          </h1>
          <p className="mt-1 text-sm text-slate-600 dark:text-slate-400">
            Check and request permissions via WebF PermissionHandler module (@webfly/permission).
          </p>
        </div>
      </header>

      <div className="flex flex-col gap-6">
        {error && (
          <div className="rounded-xl bg-red-50 p-4 text-sm text-red-700 border border-red-100 dark:bg-red-900/20 dark:border-red-900/30 dark:text-red-400">
            {error}
          </div>
        )}

        {/* Actions */}
        <div className="rounded-2xl border border-slate-200 bg-white p-6 shadow-sm dark:border-slate-800 dark:bg-slate-900/60">
          <h2 className="text-lg font-semibold text-slate-900 dark:text-slate-100">Actions</h2>
          <p className="mt-1 text-sm text-slate-600 dark:text-slate-400">
            openAppSettings, requestMultiple (camera + microphone).
          </p>
          <div className="mt-4 flex flex-wrap gap-3">
            <button
              onClick={handleOpenSettings}
              className="rounded-full px-4 py-2 text-xs font-semibold border border-slate-200 text-slate-600 transition hover:bg-slate-50 dark:border-slate-700 dark:text-slate-300 dark:hover:bg-slate-800"
            >
              Open app settings
            </button>
            <button
              onClick={handleRequestMultiple}
              disabled={loading === 'multiple'}
              className="rounded-full px-4 py-2 text-xs font-semibold text-white bg-indigo-500 hover:bg-indigo-600 disabled:opacity-50"
            >
              {loading === 'multiple' ? 'Requesting…' : 'Request camera + microphone'}
            </button>
          </div>
          {settingsOpened !== null && (
            <p className="mt-2 text-xs text-slate-500">
              openAppSettings result: {settingsOpened ? 'opened' : 'failed'}
            </p>
          )}
        </div>

        {/* Per-permission list */}
        <div className="rounded-2xl border border-slate-200 bg-white p-6 shadow-sm dark:border-slate-800 dark:bg-slate-900/60">
          <h2 className="text-lg font-semibold text-slate-900 dark:text-slate-100">
            Permissions (checkStatus / request / shouldShowRequestRationale)
          </h2>
          <p className="mt-1 text-sm text-slate-600 dark:text-slate-400">
            Tap Check to read current status; Request may show system dialog.
          </p>
          <p className="mt-2 text-xs text-amber-700 dark:text-amber-400 bg-amber-50 dark:bg-amber-900/20 rounded-lg px-3 py-2 border border-amber-200 dark:border-amber-800">
            If Bluetooth or Notification show denied: tap <strong>Request</strong> next to that row to open the system permission dialog. If no dialog appears (e.g. you previously chose &quot;Don&apos;t ask again&quot;), open <strong>Settings → Apps → WebFly → Permissions</strong> and enable them there.
          </p>
          <ul className="mt-4 space-y-3">
            {DEMO_PERMISSIONS.map((perm) => (
              <li
                key={perm}
                className="flex flex-wrap items-center gap-2 rounded-xl border border-slate-200 bg-slate-50 px-4 py-3 dark:border-slate-700 dark:bg-slate-800/50"
              >
                <span className="font-mono text-sm font-medium text-slate-800 dark:text-slate-200">
                  {perm}
                </span>
                <span className="rounded bg-slate-200 px-2 py-0.5 font-mono text-xs text-slate-700 dark:bg-slate-700 dark:text-slate-300">
                  {statuses[perm] ?? '—'}
                </span>
                {rationales[perm] !== undefined && (
                  <span className="text-xs text-slate-500">
                    rationale: {rationales[perm] ? 'yes' : 'no'}
                  </span>
                )}
                <div className="ml-auto flex gap-2">
                  <button
                    onClick={() => handleCheck(perm)}
                    disabled={loading === perm}
                    className="rounded-full border border-slate-300 px-3 py-1 text-xs font-medium text-slate-600 hover:bg-slate-100 dark:border-slate-600 dark:text-slate-400 dark:hover:bg-slate-700"
                  >
                    {loading === perm ? '…' : 'Check'}
                  </button>
                  <button
                    onClick={() => handleRequest(perm)}
                    disabled={loading === perm}
                    className="rounded-full bg-indigo-500 px-3 py-1 text-xs font-medium text-white hover:bg-indigo-600 disabled:opacity-50"
                  >
                    Request
                  </button>
                  <button
                    onClick={() => handleCheckRationale(perm)}
                    className="rounded-full border border-slate-300 px-3 py-1 text-xs font-medium text-slate-600 hover:bg-slate-100 dark:border-slate-600 dark:text-slate-400 dark:hover:bg-slate-700"
                  >
                    Rationale
                  </button>
                </div>
              </li>
            ))}
          </ul>
        </div>
      </div>
    </div>
  );
};

export default PermissionDemoPage;

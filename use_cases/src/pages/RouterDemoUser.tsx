import React, { useMemo } from 'react';
import { useNavigate, useLocation, useParams } from '@openwebf/react-router';
import { inferSegmentAfter, joinBase, safeJson } from './RouterDemoUtils';

const basePath = '/routing';

export function RouterDemoUser() {
  const { navigate } = useNavigate();
  const params = useParams();
  const location = useLocation();

  const idFromParams = (params as any)?.id as string | undefined;
  const idFromPath = inferSegmentAfter(location.pathname, 'users');
  const userId = idFromParams ?? idFromPath ?? '(missing)';

  const stateJson = useMemo(() => safeJson(location.state), [location.state]);

  const current = Number(userId);
  const next = Number.isFinite(current) ? current + 1 : 1;
  const prev = Number.isFinite(current) ? Math.max(0, current - 1) : 0;

  return (
    <div className="mx-auto max-w-3xl space-y-4 text-left">
      <div className="flex items-start justify-between gap-3">
        <h1 className="text-2xl font-semibold text-fg-primary">User</h1>
        <div className="rounded-lg border border-line px-3 py-2 bg-surface">
          <div className="text-xs text-fg-secondary">Path</div>
          <div className="font-mono text-xs text-fg">{location.pathname}</div>
        </div>
      </div>

      <div className="rounded-lg border border-line p-4 bg-surface space-y-2">
        <div className="text-sm text-fg-secondary">Params</div>
        <div className="font-mono text-sm text-fg">id = {userId}</div>
      </div>

      <div className="rounded-lg border border-line p-4 bg-surface space-y-2">
        <div className="text-sm text-fg-secondary">State</div>
        <pre className="overflow-auto rounded bg-black/30 p-3 text-xs text-fg">{stateJson}</pre>
      </div>

      <div className="grid gap-3 sm:grid-cols-2">
        <button
          className="rounded-lg bg-white/10 px-4 py-2 text-sm text-fg hover:bg-white/15"
          onClick={() => navigate(joinBase(basePath, '/'), { state: { from: location.pathname, at: Date.now() } })}
        >
          Home
        </button>
        <button
          className="rounded-lg bg-white/10 px-4 py-2 text-sm text-fg hover:bg-white/15"
          onClick={() => navigate(-1)}
        >
          Back
        </button>

        <button
          className="rounded-lg bg-white/10 px-4 py-2 text-sm text-fg hover:bg-white/15"
          onClick={() => navigate(joinBase(basePath, `/users/${prev}`), { replace: true, state: { from: location.pathname, at: Date.now() } })}
        >
          Previous user
        </button>
        <button
          className="rounded-lg bg-blue-500/70 px-4 py-2 text-sm text-white hover:bg-blue-500/80"
          onClick={() => navigate(joinBase(basePath, `/users/${next}`), { replace: true, state: { from: location.pathname, at: Date.now() } })}
        >
          Next user
        </button>
      </div>
    </div>
  );
}


import React, { useMemo, useState } from 'react';
import { useNavigate, useLocation } from '@openwebf/react-router';
import { joinBase, safeJson } from './RouterDemoUtils';

const basePath = '/routing';

export function RouterDemoHome() {
  const { navigate } = useNavigate();
  const location = useLocation();
  const [customPath, setCustomPath] = useState('/routing/users/123');

  const stateJson = useMemo(() => safeJson(location.state), [location.state]);
  const normalizedCustomPath = useMemo(() => (customPath.startsWith('/') ? customPath : `/${customPath}`), [customPath]);

  return (
    <div className="mx-auto max-w-3xl space-y-4 text-left">
      <div className="flex items-start justify-between gap-3">
        <h1 className="text-2xl font-semibold text-fg-primary">Routing Demo</h1>
        <div className="rounded-lg border border-line px-3 py-2 bg-surface">
          <div className="text-xs text-fg-secondary">Path</div>
          <div className="font-mono text-xs text-fg">{location.pathname}</div>
        </div>
      </div>

      <div className="rounded-lg border border-line p-4 space-y-2 bg-surface">
        <div className="text-sm text-fg-secondary">State</div>
        <pre className="overflow-auto rounded bg-black/30 p-3 text-xs text-fg">{stateJson}</pre>
      </div>

      <div className="grid gap-3 sm:grid-cols-2">
        <button
          className="rounded-lg border border-line bg-surface px-4 py-3 text-left hover:bg-surface-secondary"
          onClick={() => navigate(joinBase(basePath, '/about'), { state: { from: location.pathname, at: Date.now() } })}
        >
          <div className="text-sm font-semibold text-fg-primary">About</div>
          <div className="text-xs text-fg-secondary mt-1">Static route under /routing/about</div>
        </button>

        <button
          className="rounded-lg border border-line bg-surface px-4 py-3 text-left hover:bg-surface-secondary"
          onClick={() => navigate(joinBase(basePath, '/users/1'), { state: { from: location.pathname, at: Date.now() } })}
        >
          <div className="text-sm font-semibold text-fg-primary">User #1</div>
          <div className="text-xs text-fg-secondary mt-1">Dynamic route: /routing/users/:id</div>
        </button>

        <button
          className="rounded-lg border border-line bg-surface px-4 py-3 text-left hover:bg-surface-secondary"
          onClick={() => navigate(joinBase(basePath, '/users/42'), { state: { from: location.pathname, at: Date.now() } })}
        >
          <div className="text-sm font-semibold text-fg-primary">User #42</div>
          <div className="text-xs text-fg-secondary mt-1">Push to add to history</div>
        </button>

        <button
          className="rounded-lg border border-line bg-surface px-4 py-3 text-left hover:bg-surface-secondary"
          onClick={() => navigate(joinBase(basePath, '/files/docs/getting-started'), { state: { from: location.pathname, at: Date.now() } })}
        >
          <div className="text-sm font-semibold text-fg-primary">Files</div>
          <div className="text-xs text-fg-secondary mt-1">Wildcard route: /routing/files/*</div>
        </button>

        <button
          className="rounded-lg border border-line bg-surface px-4 py-3 text-left hover:bg-surface-secondary"
          onClick={() => navigate(joinBase(basePath, '/this/does-not-exist'), { state: { from: location.pathname, at: Date.now() } })}
        >
          <div className="text-sm font-semibold text-fg-primary">Not Found</div>
          <div className="text-xs text-fg-secondary mt-1">Catch-all route: /routing/*</div>
        </button>
      </div>

      <div className="rounded-lg border border-line p-4 space-y-3 bg-surface">
        <div className="text-sm font-semibold text-fg-primary">Navigate to a path</div>
        <div className="text-xs text-fg-secondary">
          Test navigation to any path using WebFRouter API.
        </div>
        <div className="flex gap-2">
          <input
            className="flex-1 rounded-md border border-line bg-surface px-3 py-2 text-sm text-fg"
            value={customPath}
            onChange={(e) => setCustomPath(e.target.value)}
            placeholder="/routing/users/123"
          />
          <button
            className="rounded-md bg-blue-500/70 px-4 py-2 text-sm text-white hover:bg-blue-500/80"
            onClick={() => navigate(normalizedCustomPath, { replace: true, state: { from: location.pathname, at: Date.now() } })}
          >
            Go
          </button>
        </div>
      </div>
    </div>
  );
}


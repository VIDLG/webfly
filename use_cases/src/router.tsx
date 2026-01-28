import React, { PropsWithChildren } from 'react';
import * as WebFLib from '@openwebf/react-router';

// WebF-only router - no browser compatibility layer
// eslint-disable-next-line @typescript-eslint/no-empty-object-type
export const RouterProvider: React.FC<PropsWithChildren<{}>> = ({ children }) => {
  return <>{children}</>;
};

// Re-export WebF router components
// eslint-disable-next-line @typescript-eslint/no-explicit-any
export const Routes: any = (WebFLib as any).Routes;
// eslint-disable-next-line @typescript-eslint/no-explicit-any
export const Route: any = (WebFLib as any).Route;
// eslint-disable-next-line @typescript-eslint/no-explicit-any
export const WebFRouterLink: any = (WebFLib as any).WebFRouterLink;

// Re-export WebF router API (for cross-app navigation)
// eslint-disable-next-line @typescript-eslint/no-explicit-any
export const WebFRouter = (WebFLib as any).WebFRouter;

export const isWebFEnvironment = true;


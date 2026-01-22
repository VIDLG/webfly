import React, { PropsWithChildren } from 'react';
import * as WebFLib from '@openwebf/react-router';

// WebF-only router - no browser compatibility layer
export const RouterProvider: React.FC<PropsWithChildren<{}>> = ({ children }) => {
  return <>{children}</>;
};

// Re-export WebF router components
export const Routes: any = (WebFLib as any).Routes;
export const Route: any = (WebFLib as any).Route;
export const WebFRouterLink: any = (WebFLib as any).WebFRouterLink;

// Re-export WebF router API (for cross-app navigation)
export const WebFRouter = (WebFLib as any).WebFRouter;

export const isWebFEnvironment = true;


import { Route, Routes } from '@openwebf/react-router'
import React, { Suspense, lazy } from 'react'
import { ThemeProvider } from './hooks/theme'

const routeTheme: 'material' | 'cupertino' = 'material'

const HomePage = lazy(() => import('./pages/HomePage'))
const ProductDetailPage = lazy(() => import('./pages/ProductDetailPage'))
const ProductListPage = lazy(() => import('./pages/ProductListPage'))
const ProfilePage = lazy(() => import('./pages/ProfilePage'))
const SettingsPage = lazy(() => import('./pages/SettingsPage'))
const LEDStripPage = lazy(() => import('./pages/LEDStripPage'))
const LEDEffectPreviewPage = lazy(() => import('./pages/LEDEffectPreviewPage'))
const BleDemoPage = lazy(() => import('./pages/BleDemoPage'))

const withSuspense = (element: React.ReactNode) => (
  <Suspense fallback={<div className="p-4">Loading…</div>}>
    {/* Ensure block level display to avoid WebF layout issues. */}
    <div className="block h-screen w-full overflow-y-auto bg-slate-50 text-slate-900 transition-colors duration-300 dark:bg-slate-950 dark:text-slate-100">
      {element}
    </div>
  </Suspense>
)

class ErrorBoundary extends React.Component<
  { children: React.ReactNode },
  { error: unknown; errorInfo?: React.ErrorInfo }
> {
  state: { error: unknown; errorInfo?: React.ErrorInfo } = { error: null }

  static getDerivedStateFromError(error: unknown) {
    return { error }
  }

  componentDidCatch(error: unknown, errorInfo: React.ErrorInfo) {
    this.setState({ error, errorInfo })
  }

  render() {
    if (this.state.error) {
      const href = typeof window !== 'undefined' ? window.location.href : ''
      const pathname = typeof window !== 'undefined' ? window.location.pathname : ''
      const search = typeof window !== 'undefined' ? window.location.search : ''
      const hash = typeof window !== 'undefined' ? window.location.hash : ''

      return (
        <div className="p-4">
          <div className="mb-2 text-base font-semibold">App crashed</div>
          <div className="mb-3 text-xs opacity-80">
            A route chunk or render threw an error. This is usually more helpful than an infinite
            loading spinner.
          </div>
          <pre className="whitespace-pre-wrap text-xs">
            {JSON.stringify(
              {
                location: { href, pathname, search, hash },
                error: String(this.state.error),
                componentStack: this.state.errorInfo?.componentStack,
              },
              null,
              2,
            )}
          </pre>
        </div>
      )
    }

    return this.props.children
  }
}

function NotFoundPage() {
  const href = typeof window !== 'undefined' ? window.location.href : ''
  const pathname = typeof window !== 'undefined' ? window.location.pathname : ''
  const search = typeof window !== 'undefined' ? window.location.search : ''
  const hash = typeof window !== 'undefined' ? window.location.hash : ''

  return (
    <div className="p-4">
      <div className="mb-2 text-base font-semibold">Route not found</div>
      <div className="mb-3 text-xs opacity-80">
        If you deep-linked via Launcher Advanced path, ensure the route path is a pathname like{' '}
        <code>/led</code> and use query like <code>?css=0</code> only if the runtime preserves{' '}
        <code>window.location.search</code>.
      </div>
      <pre className="whitespace-pre-wrap text-xs">
        {JSON.stringify({ href, pathname, search, hash }, null, 2)}
      </pre>
    </div>
  )
}

function App() {
  const routes: Array<{ path: string; title: string; element: React.ReactNode }> = [
    { path: '/', title: 'Home', element: <HomePage /> },
    { path: '/index', title: 'Home', element: <HomePage /> },
    { path: '/home', title: 'Home', element: <HomePage /> },
    { path: '/led', title: 'LED Strip Demo', element: <LEDStripPage /> },
    { path: '/led/:effectId', title: 'LED Effect', element: <LEDEffectPreviewPage /> },
    { path: '/profile', title: 'Profile', element: <ProfilePage /> },
    { path: '/settings', title: 'Settings', element: <SettingsPage /> },
    { path: '/products', title: 'Products', element: <ProductListPage /> },
    { path: '/product/:productId', title: 'Product Detail', element: <ProductDetailPage /> },
    { path: '/ble', title: 'BLE Demo', element: <BleDemoPage /> },
  ]

  return (
    <ThemeProvider>
      <ErrorBoundary>
        <Routes>
          {routes.map((r) => (
            <Route
              key={r.path}
              path={r.path}
              element={withSuspense(r.element)}
              title={r.title}
              theme={routeTheme}
            />
          ))}
          <Route path="*" element={<NotFoundPage />} title="Not Found" theme={routeTheme} />
        </Routes>
      </ErrorBoundary>
    </ThemeProvider>
  )
}

export default App

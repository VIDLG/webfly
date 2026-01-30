import { Route, Routes } from '@openwebf/react-router'
import React, { Suspense, lazy } from 'react'

const HomePage = lazy(() => import('./pages/HomePage'))
const ProductDetailPage = lazy(() => import('./pages/ProductDetailPage'))
const ProductListPage = lazy(() => import('./pages/ProductListPage'))
const ProfilePage = lazy(() => import('./pages/ProfilePage'))
const SettingsPage = lazy(() => import('./pages/SettingsPage'))
const LEDStripPage = lazy(() => import('./pages/LEDStripPage'))
const LEDEffectPreviewPage = lazy(() => import('./pages/LEDEffectPreviewPage'))

const withSuspense = (element: React.ReactNode) => (
  <Suspense fallback={<div style={{ padding: 16 }}>Loading…</div>}>
    {element}
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
        <div style={{ padding: 16 }}>
          <div style={{ fontSize: 16, fontWeight: 600, marginBottom: 8 }}>App crashed</div>
          <div style={{ fontSize: 12, opacity: 0.8, marginBottom: 12 }}>
            A route chunk or render threw an error. This is usually more helpful than an infinite
            loading spinner.
          </div>
          <pre style={{ fontSize: 12, whiteSpace: 'pre-wrap' }}>
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
    <div style={{ padding: 16 }}>
      <div style={{ fontSize: 16, fontWeight: 600, marginBottom: 8 }}>Route not found</div>
      <div style={{ fontSize: 12, opacity: 0.8, marginBottom: 12 }}>
        If you deep-linked via Launcher Advanced path, ensure the route path is a pathname
        like <code>/led</code> and use query like <code>?css=0</code> only if the runtime
        preserves <code>window.location.search</code>.
      </div>
      <pre style={{ fontSize: 12, whiteSpace: 'pre-wrap' }}>
        {JSON.stringify({ href, pathname, search, hash }, null, 2)}
      </pre>
    </div>
  )
}

function App() {
  return (
    <ErrorBoundary>
      <Routes>
        <Route path="/" element={withSuspense(<HomePage />)} title="Home" />
        <Route path="/index" element={withSuspense(<HomePage />)} title="Home" />
        <Route path="/home" element={withSuspense(<HomePage />)} title="Home" />
        <Route path="/led" element={withSuspense(<LEDStripPage />)} title="LED Strip Demo" />
        <Route path="/led/:effectId" element={withSuspense(<LEDEffectPreviewPage />)} title="LED Effect" />
        <Route path="/profile" element={withSuspense(<ProfilePage />)} title="Profile" />
        <Route path="/settings" element={withSuspense(<SettingsPage />)} title="Settings" />
        <Route path="/products" element={withSuspense(<ProductListPage />)} title="Products" />
        <Route path="/product/:productId" element={withSuspense(<ProductDetailPage />)} title="Product Detail" />
        <Route path="*" element={<NotFoundPage />} title="Not Found" />
      </Routes>
    </ErrorBoundary>
  )
}

export default App

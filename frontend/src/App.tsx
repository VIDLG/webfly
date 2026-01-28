import { Route, Routes } from '@openwebf/react-router'
import { Suspense, lazy } from 'react'

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

function App() {
  return (
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
    </Routes>
  )
}

export default App

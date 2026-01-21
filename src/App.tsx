import { Route, Routes } from '@openwebf/react-router'
import HomePage from './pages/HomePage'
import ProductDetailPage from './pages/ProductDetailPage'
import ProductListPage from './pages/ProductListPage'
import ProfilePage from './pages/ProfilePage'
import SettingsPage from './pages/SettingsPage'

function App() {
  return (
    <Routes>
      <Route path="/" element={<HomePage />} title="Home" />
      <Route path="/index" element={<HomePage />} title="Home" />
      <Route path="/home" element={<HomePage />} title="Home" />
      <Route path="/profile" element={<ProfilePage />} title="Profile" />
      <Route path="/settings" element={<SettingsPage />} title="Settings" />
      <Route path="/products" element={<ProductListPage />} title="Products" />
      <Route path="/product/:productId" element={<ProductDetailPage />} title="Product Detail" />
    </Routes>
  )
}

export default App

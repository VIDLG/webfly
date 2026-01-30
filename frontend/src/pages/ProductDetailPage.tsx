import { useLocation, useParams, useNavigate } from '@openwebf/react-router'

type Product = {
  id: number
  name: string
  price: number
  description: string
}

function ProductDetailPage() {
  const params = useParams() as unknown as { productId?: string }
  const location = useLocation()
  const { navigate } = useNavigate()
  const stateProduct = (location.state as { product?: Product; source?: string } | null)?.product
  const source = (location.state as { product?: Product; source?: string } | null)?.source ?? 'fallback'

  const effectiveProductId = params.productId

  // Use fake data if no product passed through state
  const product: Product = stateProduct ?? {
    id: Number(effectiveProductId) || 0,
    name: `Product ${effectiveProductId}`,
    price: 299,
    description: 'This is a fallback product generated from route parameters',
  }

  return (
    <div className="mx-auto flex min-h-screen max-w-3xl flex-col gap-6 px-6 py-12">
      <header className="space-y-2">
        <h1 className="text-3xl font-semibold text-slate-900 dark:text-slate-100">{product.name}</h1>
        <p className="text-sm text-slate-600 dark:text-slate-400">ID: {effectiveProductId} • Method: {source}</p>
      </header>

      <div className="rounded-2xl border border-slate-200 bg-white p-6 dark:border-slate-800 dark:bg-slate-900/60">
        <p className="text-lg font-semibold text-sky-400">¥{product.price}</p>
        <p className="mt-2 text-sm text-slate-600 dark:text-slate-400">{product.description}</p>
      </div>

      <div className="flex gap-3">
        <button
          className="rounded-full bg-sky-500 px-5 py-2 text-sm font-semibold text-white transition hover:bg-sky-400"
          onClick={() => navigate('/products', { state: { from: 'product' } })}
        >
          Back to Products
        </button>
        <button
          className="rounded-full border border-slate-300 px-5 py-2 text-sm text-slate-900 transition hover:opacity-90 dark:border-slate-700 dark:text-slate-100"
          onClick={() => navigate(-1)}
        >
          Go Back
        </button>
      </div>

      <div className="rounded-2xl border border-slate-200 bg-white p-4 text-sm text-slate-600 dark:border-slate-800 dark:bg-slate-900/60 dark:text-slate-400">
        💡 <strong>Using useParams():</strong> Route parameter <code className="rounded bg-white/70 px-1.5 py-0.5 text-sky-600 dark:bg-slate-900/60">productId</code> is extracted from URL path.
      </div>
    </div>
  )
}

export default ProductDetailPage

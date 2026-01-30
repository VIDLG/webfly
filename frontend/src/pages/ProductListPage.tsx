import { useNavigate } from '@openwebf/react-router'

type Product = {
  id: number
  name: string
  price: number
  description: string
}

const PRODUCTS: Product[] = [
  { id: 1, name: 'WebF Starter Kit', price: 199, description: 'Quick start for your hybrid app' },
  { id: 2, name: 'Native UI Pack', price: 299, description: 'UI components adapted for native platforms' },
  { id: 3, name: 'Routing Toolkit', price: 99, description: 'Built-in native navigation experience' },
]

function ProductListPage() {
  const { navigate } = useNavigate()

  const openProduct = (product: Product) => {
    navigate(`/product/${product.id}`, {
      state: { product },
    })
  }

  return (
    <div className="mx-auto flex min-h-screen max-w-4xl flex-col gap-6 px-6 py-12">
      <header className="space-y-2">
        <h1 className="text-3xl font-semibold text-slate-900 dark:text-slate-100">Products</h1>
        <p className="text-sm text-slate-600 dark:text-slate-400">
          All products use <code className="rounded bg-white/70 px-1 text-xs text-sky-600 dark:bg-slate-900/60">useNavigate()</code> for navigation
        </p>
      </header>

      <div className="grid gap-4">
        {PRODUCTS.map((product) => (
          <button
            key={product.id}
            className="rounded-2xl border border-slate-200 bg-white p-5 text-left transition hover:opacity-95 dark:border-slate-800 dark:bg-slate-900/60"
            onClick={() => openProduct(product)}
          >
            <div className="flex items-center justify-between">
              <h2 className="text-lg font-semibold text-slate-900 dark:text-slate-100">{product.name}</h2>
              <span className="text-sm text-sky-600">¥{product.price}</span>
            </div>
            <p className="mt-2 text-sm text-slate-600 dark:text-slate-400">{product.description}</p>
          </button>
        ))}
      </div>

      <button
        className="self-start rounded-full border border-slate-300 px-5 py-2 text-sm text-slate-900 transition hover:opacity-90 dark:border-slate-700 dark:text-slate-100"
        onClick={() => navigate(-1)}
      >
        Go Back
      </button>

      <div className="rounded-2xl border border-slate-200 bg-white p-4 text-sm text-slate-600 dark:border-slate-800 dark:bg-slate-900/60 dark:text-slate-400">
        💡 <strong>Teaching Demo:</strong> Click different products to see both navigation methods.
      </div>
    </div>
  )
}

export default ProductListPage

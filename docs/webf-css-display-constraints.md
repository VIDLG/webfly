# WebF CSS Display Property Constraints

## Problem

When using Tailwind CSS with WebF, you may encounter layout errors like:

```
LAYOUT ERROR: Failed assertion: line 392 pos 7: 'box.renderStyle.display == CSSDisplay.inlineBlock || 
box.renderStyle.display == CSSDisplay.inlineFlex || 
(box.renderStyle.display == CSSDisplay.inline &&'
```

This error occurs because WebF's `inline_items_builder.dart` has strict constraints on CSS `display` properties when elements are rendered in an **inline formatting context**.

## Root Cause

WebF's layout engine (`inline_items_builder.dart`) only supports certain `display` values when elements are in an inline formatting context:

- ✅ `inline-block`
- ✅ `inline-flex`  
- ✅ `inline`

❌ **NOT supported in inline context:**
- `block`
- `flex` (without explicit context)
- Other block-level display values

Semantic HTML elements like `<header>`, `<h1>`, `<h2>`, `<p>`, `<button>` have default `display` values that may not be compatible with inline formatting contexts, causing layout errors.

## Solution

Ensure all route pages start in a **block formatting context** by wrapping them in a `block` div.

### Implementation

In `frontend/src/App.tsx`, the `withSuspense` function wraps all route elements:

```tsx
const withSuspense = (element: React.ReactNode) => (
  <div className="block">  {/* ← This creates block formatting context */}
    <Suspense fallback={<div style={{ padding: 16 }}>Loading…</div>}>
      {element}
    </Suspense>
  </div>
)
```

This ensures:
1. ✅ Every route page starts in a block formatting context
2. ✅ Semantic HTML elements work correctly
3. ✅ Tailwind CSS utilities work as expected
4. ✅ No need to add `block` class to each page component

### Why Not in App Root?

Adding `block` at the App root level (`<ThemeProvider>` or `<ErrorBoundary>`) doesn't work because:
- WebF's routing system (`Routes`/`Route`) may create new formatting contexts
- Intermediate components may affect DOM structure
- Each route page is independently rendered

### Why Not in Each Page?

While adding `block` to each page's root element works, it's:
- ❌ Repetitive and error-prone
- ❌ Easy to forget for new pages
- ❌ Harder to maintain

Wrapping in `withSuspense` provides a centralized solution.

## Best Practices

1. **Always use `withSuspense`** for route elements in `App.tsx`
2. **Don't add `block` to page components** - it's already handled
3. **Use semantic HTML freely** - `<header>`, `<h1>`, `<p>`, `<button>` all work correctly
4. **Use Tailwind CSS normally** - `flex`, `grid`, etc. work in block contexts

## Example: Before vs After

### ❌ Before (Causes Layout Error)

```tsx
// App.tsx
const withSuspense = (element: React.ReactNode) => (
  <Suspense fallback={<div>Loading…</div>}>
    {element}
  </Suspense>
)

// LEDStripPage.tsx
export default function LEDStripPage() {
  return (
    <div className="min-h-screen bg-slate-950">  {/* Missing block context */}
      <header>  {/* May cause layout error */}
        <h1>Title</h1>
      </header>
    </div>
  )
}
```

### ✅ After (Works Correctly)

```tsx
// App.tsx
const withSuspense = (element: React.ReactNode) => (
  <div className="block">  {/* Creates block context */}
    <Suspense fallback={<div>Loading…</div>}>
      {element}
    </Suspense>
  </div>
)

// LEDStripPage.tsx
export default function LEDStripPage() {
  return (
    <div className="min-h-screen bg-slate-950">  {/* No block needed */}
      <header>  {/* Works correctly */}
        <h1>Title</h1>
      </header>
    </div>
  )
}
```

## Technical Details

### WebF Display Property Support

According to `docs/css_properties.json5`, WebF supports these `display` keywords:

- `inline`
- `block`
- `inline-block`
- `flex`
- `inline-flex`
- `grid`
- `inline-grid`
- `table`, `inline-table`, and table-related values
- `none`
- `contents`
- `flow-root`
- And others...

However, **the context matters**. In an inline formatting context, only `inline`, `inline-block`, and `inline-flex` are allowed.

### Block Formatting Context

A block formatting context is created by elements with:
- `display: block`
- `display: flex`
- `display: grid`
- `display: flow-root`
- And other block-level display values

Once in a block formatting context, child elements can use any supported `display` value.

## Related Issues

- See `docs/webf-issue-renderflowlayout-mutated-during-layout.md` for other WebF layout issues
- See `docs/hybrid-routing-workarounds.md` for routing-related workarounds

## References

- WebF CSS Properties: `docs/css_properties.json5`
- WebF Layout Engine: `inline_items_builder.dart` (in WebF source)
- Tailwind CSS: https://tailwindcss.com/docs

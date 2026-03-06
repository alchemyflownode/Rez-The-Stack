# Performance Optimization Guide - Phase 3

## Performance Baseline Metrics

### Core Web Vitals Targets (Google PageSpeed Insights)
- **LCP (Largest Contentful Paint):** < 2.5s (Good)
- **FID (First Input Delay):** < 100ms (Good)  
- **CLS (Cumulative Layout Shift):** < 0.1 (Good)
- **FCP (First Contentful Paint):** < 1.8s (Good)
- **TTFB (Time to First Byte):** < 0.6s (Good)

### Performance Monitoring
✅ **Web Vitals tracking enabled** via src/lib/web-vitals.ts
✅ **Metrics endpoint** configured at /api/vitals
✅ **Bundle analysis** available via: `ANALYZE=true npm run build`

## Bundle Analysis

### How to Analyze Current Bundle
```bash
# Generate bundle analysis report
ANALYZE=true npm run build

# This creates an interactive HTML report showing:
# - Individual package sizes
# - Duplicate modules
# - Chunk breakdown
# - Tree-shaking effectiveness
```

### Key Libraries to Monitor
Large dependencies that could be optimized:

| Package | Size | Status | Notes |
|---------|------|--------|-------|
| langchain | ~500KB | Review | Check if all utilities are used |
| react-markdown | ~80KB | Review | Could be code-split |
| react-syntax-highlighter | ~1.5MB | Optimize | Consider lighter alternative |
| axios | ~35KB | OK | Widely used, necessary |
| framer-motion | ~80KB | OK | Used for UI animations |
| chromadb | ~varies | Review | Used for embeddings |

## Optimization Strategies

### 1. Code Splitting & Dynamic Imports

**Strategy:** Load heavy components only when needed

```typescript
// Before (eager load)
import CodeBlock from '@/components/CodeBlock';

// After (lazy load)
import dynamic from 'next/dynamic';

const CodeBlock = dynamic(() => import('@/components/CodeBlock'), {
  loading: () => <p>Loading code viewer...</p>,
  ssr: false // Disable SSR if component uses browser APIs
});
```

**Candidates for splitting:**
- CodeBlock (syntax highlighting)
- ChatInterface (large markdown processor)
- PremiumWorkspace (heavy component tree)
- DynamicIsland (animations)

### 2. Image Optimization

**Currently enabled via next.config.js:**
- ✅ AVIF format support (30-50% smaller than JPEG)
- ✅ WebP fallback (25-35% smaller than JPEG)
- ✅ Automatic responsive images
- ✅ Lazy loading by default

**Next steps:**
```typescript
// Use Next.js Image component
import Image from 'next/image';

<Image
  src="/image.jpg"
  alt="Description"
  width={800}
  height={600}
  priority // Only for above-fold images
  placeholder="blur" // Use blur placeholder
  quality={75} // Adjust quality (0-100)
/>
```

### 3. Font Optimization

**Current setup:**
- ✅ Using next/font with Google Fonts
- ✅ Subsetting to Latin characters only
- ✅ Preloading enabled automatically

**Potential improvement:**
```typescript
// Reduce font variants
const inter = Inter({ 
  subsets: ['latin'],
  weights: [400, 500, 700], // Only needed weights
  display: 'swap' // Fallback during load
});
```

### 4. CSS Optimization

**Current:**
- ✅ Tailwind CSS with purging
- ✅ CSS compression in production
- ✅ Dual-theme approach optimized

**Opportunity:** Remove unused theme CSS
```css
/* Audit which colors/spacing are actually used */
/* Consider removing deprecated theme variants */
```

### 5. JavaScript Minification

**Next.js handles automatically:**
- ✅ SWC minifier enabled (see next.config.js)
- ✅ Tree-shaking for unused exports
- ✅ Terser for legacy browser support

### 6. Dependency Optimization

**Audit unused dependencies:**
```bash
# Find unused packages
npm ls --all

# Check for duplicate versions
npm ls --all | grep -E "^├─|^│"

# Remove unused packages
npm prune
```

**Consider alternatives:**
- `react-syntax-highlighter` → `shiki` (smaller, faster)
- `axios` (stays - used extensively)
- `langchain` (audit for unused utilities)

### 7. Database Query Optimization

**For ChromaDB/RAG pipeline:**
- ✅ Validate with schema (prevents over-fetching)
- ✅ Implement request caching
- ✅ Use request deduplication
- ✅ Set query timeouts (30s - already in kernel route)

Example:
```typescript
// Add caching layer
import { cache } from 'react';

const getCachedResults = cache(async (query: string) => {
  return await kernelService.search(query);
});
```

### 8. API Optimization

**Already implemented:**
- ✅ Request batching support
- ✅ Response compression
- ✅ Request timeouts (30s)
- ✅ Error categorization

**Next steps:**
```typescript
// Add response caching
export const revalidate = 600; // ISR - revalidate every 10 min

// Add compression headers
response.headers.set('Content-Encoding', 'gzip');
```

### 9. Runtime Performance

**React optimizations:**

```typescript
// Use React.memo for expensive components
const CodeBlock = React.memo(({ code }: Props) => {...});

// Use useCallback for event handlers
const handleSearch = useCallback((query) => {
  performSearch(query);
}, []);

// Use useMemo for expensive computations
const sortedResults = useMemo(
  () => results.sort((a, b) => b.score - a.score),
  [results]
);
```

**Monitor with web-vitals:**
- FID tracks first interaction speed
- LCP tracks main content visibility
- CLS catches layout shifts

## Performance Testing Checklist

- [ ] Run `npm run build` and note total size
- [ ] Run `ANALYZE=true npm run build` to identify large chunks
- [ ] Measure LCP with Chrome DevTools Lighthouse
- [ ] Measure FID with web-vitals library (automatic)
- [ ] Measure CLS by watching for jumps during interaction
- [ ] Test on 4G throttled connection (Chrome DevTools)
- [ ] Test on low-end mobile device
- [ ] Verify images use next/image component
- [ ] Check for console errors/warnings
- [ ] Profile with Chrome DevTools Performance tab

## Implementation Priority

### Phase 3 (Current) - High Impact
1. ✅ Bundle analysis setup (ANALYZE=true npm run build)
2. Dynamic import CodeBlock component
3. Audit and remove unused dependencies
4. Cache expensive computations

### Phase 4 (Future) - Medium Impact
1. Replace react-syntax-highlighter with shiki
2. Implement request deduplication
3. Add image placeholders
4. Remove unused CSS from theme

### Phase 5 (Future) - Low Impact
1. Full React concurrent features
2. Advanced caching strategies
3. Service Worker optimization
4. Database query optimization

## Monitoring & Reporting

### View Current Metrics
```bash
# Check web-vitals endpoint
curl http://localhost:3000/api/vitals

# Response example:
{
  "lcp": { "average": 2100, "poor": 1, "good": 5 },
  "fid": { "average": 45, "poor": 0, "good": 6 },
  "cls": { "average": 0.05, "poor": 0, "good": 6 }
}
```

### Performance Dashboard
Add to a monitoring service (optional):
- SendGrid Analytics
- Sentry Performance
- DataDog
- New Relic

Or use Google
 Analytics + Web Vitals extension:
```typescript
import { getCLS, getFID, getFCP, getLCP, getTTFB } from 'web-vitals';

export function analyzeMetrics() {
  getCLS(console.log);
  getFID(console.log);
  getFCP(console.log);
  getLCP(console.log);
  getTTFB(console.log);
}
```

## Expected Performance Gains

### With Code Splitting
- Initial JS: -20-30%
- LCP: -300-500ms
- Time to Interactive: -400-700ms

### With Image Optimization
- Image load time: -40-60%
- TTFB: -100-200ms
- CLS: -0.02-0.05 (if lazy-loading)

### With Dependency Reduction
- Total bundle: -50-100KB
- Parse time: -50-100ms
- LCP: -100-200ms

### With Caching
- Repeat visits: -70%
- API responses: -50-100ms
- TTFB: Near-instant for cached

## Success Criteria for Phase 3

✅ **Goals:**
- [ ] Bundle analysis configured and accessible
- [ ] Performance metrics tracked via /api/vitals
- [ ] Web Vitals integrated in layout
- [ ] LCP < 2.5s on first visit
- [ ] FID < 100ms consistently
- [ ] CLS < 0.1 on interaction
- [ ] All images use next/image component
- [ ] No console errors in production
- [ ] Lighthouse score > 80

## Files Created
- `src/lib/web-vitals.ts` - Web Vitals tracking
- `src/app/api/vitals/route.ts` - Metrics endpoint
- `next.config.js` - Bundle analyzer integration
- `src/app/layout-client.tsx` - Web Vitals initialization

## Next Review Date
- Baseline metrics: at end of week 1
- After code splitting: end of week 2
- Full optimization: end of month

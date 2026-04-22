/**
 * Nyingmapa Calendar — CDN Image Cache Service Worker
 *
 * WHY this exists:
 *   Caches WebP images from the Cloudflare CDN worker for 30 days in the
 *   browser's Cache Storage — so repeat visits serve images from disk (zero
 *   bandwidth, instant load).
 *
 * SCOPE:
 *   ✅  Caches:  *.webp / *.jpg / *.png from Cloudflare CDN worker
 *   ❌  Skips:   *.json  — managed by RemoteDataCache (hash-based sync).
 *               Caching JSON here would block app from seeing updates.
 *
 * STRATEGY: cache-first
 *   1. Check Cache Storage — if fresh (< 30 days) → serve immediately (0 bandwidth)
 *   2. Otherwise fetch from CDN, store in cache, serve response
 *   3. If offline and stale cache exists → serve stale (better than nothing)
 */

const CACHE_NAME = 'nmc-images-v3';
const TTL_MS     = 30 * 24 * 60 * 60 * 1000; // 30 days
const CDN_HOST   = 'ittle-term-2262.phungducmanh18072005.workers.dev';
const TS_HEADER  = 'x-nmc-at';

// ── Fetch intercept ──────────────────────────────────────────────────────────

self.addEventListener('fetch', event => {
  const url = event.request.url;

  // Only intercept CDN image requests
  if (!url.includes(CDN_HOST))   return;
  if (!url.endsWith('.webp') &&
      !url.endsWith('.jpg')  &&
      !url.endsWith('.png'))     return;

  event.respondWith(serveImage(event.request));
});

async function serveImage(request) {
  const cache  = await caches.open(CACHE_NAME);
  const cached = await cache.match(request);

  if (cached) {
    const cachedAt = parseInt(cached.headers.get(TS_HEADER) || '0', 10);
    if (Date.now() - cachedAt < TTL_MS) {
      return cached; // ✅ cache hit — zero bandwidth
    }
  }

  // Cache miss or expired — fetch from CDN
  try {
    const response = await fetch(request);
    if (response.ok) {
      const buffer  = await response.arrayBuffer();
      const headers = new Headers(response.headers);
      headers.set(TS_HEADER, String(Date.now()));
      // Store with timestamp header for TTL tracking
      await cache.put(request, new Response(buffer, {
        status: response.status, statusText: response.statusText, headers,
      }));
      // Return a fresh copy (original headers, no timestamp header leak)
      return new Response(buffer, {
        status: response.status, statusText: response.statusText,
        headers: new Headers(response.headers),
      });
    }
    return response;
  } catch (_) {
    // Offline — return stale cache if available
    return cached ?? new Response('', { status: 503 });
  }
}

// ── Activate: remove old cache versions ─────────────────────────────────────

self.addEventListener('activate', event => {
  event.waitUntil(
    caches.keys().then(keys =>
      Promise.all(keys.filter(k => k !== CACHE_NAME).map(k => caches.delete(k))),
    ),
  );
  self.clients.claim();
});

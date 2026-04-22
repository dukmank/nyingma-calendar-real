/**
 * Nyingmapa Calendar — Cloudflare Worker (CDN Proxy)
 * ====================================================
 * Deploy this as a Cloudflare Worker to serve all B2 assets for FREE.
 *
 * HOW IT WORKS:
 *   Browser → Cloudflare Worker → Backblaze B2
 *
 *   Cloudflare + Backblaze are Bandwidth Alliance partners — egress from B2
 *   through Cloudflare is completely FREE, eliminating B2 download costs.
 *   Cloudflare also caches responses at its global edge (200+ cities),
 *   making the app faster worldwide.
 *
 * SETUP (one-time, ~10 minutes):
 *   1. Sign up at cloudflare.com (free plan is sufficient)
 *   2. Go to Workers & Pages → Create Worker
 *   3. Paste this entire file into the editor
 *   4. Deploy → note the worker URL: https://nmc-cdn.YOUR_ACCOUNT.workers.dev
 *   5. Update lib/core/constants/app_constants.dart:
 *        static const String cdnBaseUrl = 'https://nmc-cdn.YOUR_ACCOUNT.workers.dev';
 *   6. Rebuild and redeploy the app
 *
 * OPTIONAL (custom domain):
 *   - Add a custom route like cdn.vajralotusfoundation.org/* to the worker
 *   - Then use: static const String cdnBaseUrl = 'https://cdn.vajralotusfoundation.org';
 *
 * CACHE BEHAVIOUR:
 *   - Images (*.webp): cached at Cloudflare edge for 1 year
 *   - JSON data files: cached for 10 minutes (allows updates to propagate)
 *   - manifest.json: NOT cached (always fetched fresh so hash-sync works)
 *   - Cloudflare automatically compresses JSON with gzip/brotli (further savings)
 */

const B2_BASE = 'https://f005.backblazeb2.com/file/nyingma-assets2';

// Cache TTLs
const TTL_IMAGE    = 365 * 24 * 3600; // 1 year  — images rarely change
const TTL_DATA     = 600;             // 10 min  — allow data updates to propagate
const TTL_MANIFEST = 0;              // no cache — must always be fresh for hash-sync

export default {
  async fetch(request) {
    const url      = new URL(request.url);
    const path     = url.pathname;           // e.g. /data/calendar/2026_04.json
    const b2Url    = `${B2_BASE}${path}`;
    const isImage  = path.endsWith('.webp') || path.endsWith('.jpg') || path.endsWith('.png');
    const isMfest  = path.endsWith('manifest.json');

    // Determine cache TTL
    const ttl = isMfest ? TTL_MANIFEST : isImage ? TTL_IMAGE : TTL_DATA;

    // Build the upstream request with CORS headers
    const b2Req = new Request(b2Url, {
      method:  request.method,
      headers: { 'User-Agent': 'NyingmapaCalendar/1.0' },
    });

    // Check Cloudflare cache first
    const cache    = caches.default;
    const cacheKey = new Request(b2Url);
    const cached   = ttl > 0 ? await cache.match(cacheKey) : null;
    if (cached) return addCorsHeaders(cached, url.origin);

    // Forward to B2
    let b2Response;
    try {
      b2Response = await fetch(b2Req);
    } catch (e) {
      return new Response('B2 fetch error: ' + e.message, { status: 502 });
    }

    if (!b2Response.ok) {
      return addCorsHeaders(new Response(b2Response.body, {
        status:  b2Response.status,
        headers: b2Response.headers,
      }), url.origin);
    }

    // Build cacheable response with long Cache-Control
    const headers = new Headers(b2Response.headers);
    headers.set('Access-Control-Allow-Origin', '*');
    headers.set('Access-Control-Allow-Methods', 'GET, HEAD');
    if (ttl > 0) {
      headers.set('Cache-Control', `public, max-age=${ttl}, immutable`);
    } else {
      headers.set('Cache-Control', 'no-store');
    }

    const response = new Response(b2Response.body, {
      status:  b2Response.status,
      headers,
    });

    // Store in Cloudflare edge cache (async — don't block response)
    if (ttl > 0) {
      const ctx = globalThis.executionCtx ?? { waitUntil: () => {} };
      ctx.waitUntil(cache.put(cacheKey, response.clone()));
    }

    return response;
  },
};

function addCorsHeaders(response, _origin) {
  const headers = new Headers(response.headers);
  headers.set('Access-Control-Allow-Origin', '*');
  return new Response(response.body, { status: response.status, headers });
}

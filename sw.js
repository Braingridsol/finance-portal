// Finance Portal — Service Worker
// Cache-first for app shell & libs; network-first for Supabase API.

const CACHE_VERSION = 'fp-v1.6.0';
const APP_SHELL = [
  './finance-tracker.html',
  './manifest.webmanifest',
  './icon-192.svg',
  './icon-512.svg',
  './icon-maskable.svg',
  'https://fonts.googleapis.com/css2?family=Inter:wght@400;500;600;700;800&display=swap',
  'https://cdn.jsdelivr.net/npm/chart.js@4.4.0/dist/chart.umd.min.js',
  'https://unpkg.com/lucide@latest/dist/umd/lucide.js',
  'https://cdn.jsdelivr.net/npm/xlsx@0.18.5/dist/xlsx.full.min.js',
  'https://cdn.jsdelivr.net/npm/jszip@3.10.1/dist/jszip.min.js',
  'https://cdn.jsdelivr.net/npm/@supabase/supabase-js@2'
];

self.addEventListener('install', (event) => {
  event.waitUntil(
    caches.open(CACHE_VERSION).then((cache) => {
      // Cache app shell, swallow individual failures (e.g. CDN errors won't block install)
      return Promise.all(APP_SHELL.map((url) =>
        cache.add(url).catch((err) => console.warn('Skip cache:', url, err.message))
      ));
    }).then(() => self.skipWaiting())
  );
});

self.addEventListener('activate', (event) => {
  event.waitUntil(
    caches.keys().then((keys) =>
      Promise.all(keys.filter((k) => k !== CACHE_VERSION).map((k) => caches.delete(k)))
    ).then(() => self.clients.claim())
  );
});

self.addEventListener('fetch', (event) => {
  const req = event.request;
  if (req.method !== 'GET') return; // only cache GETs
  const url = new URL(req.url);

  // Supabase API — network-first, no caching
  if (url.hostname.endsWith('.supabase.co') || url.hostname.endsWith('.supabase.in')) {
    event.respondWith(fetch(req).catch(() => new Response(JSON.stringify({ error: 'offline' }), { status: 503, headers: { 'Content-Type': 'application/json' } })));
    return;
  }

  // Google Fonts CSS — stale-while-revalidate
  if (url.hostname === 'fonts.googleapis.com' || url.hostname === 'fonts.gstatic.com') {
    event.respondWith(
      caches.open(CACHE_VERSION).then(async (cache) => {
        const cached = await cache.match(req);
        const network = fetch(req).then((res) => { cache.put(req, res.clone()); return res; }).catch(() => null);
        return cached || network || new Response('', { status: 504 });
      })
    );
    return;
  }

  // App shell + CDN libs — cache-first
  event.respondWith(
    caches.match(req).then((cached) => {
      if (cached) return cached;
      return fetch(req).then((res) => {
        // Cache same-origin and known CDN responses
        if (res.ok && (url.origin === self.location.origin ||
            url.hostname === 'cdn.jsdelivr.net' ||
            url.hostname === 'unpkg.com')) {
          const clone = res.clone();
          caches.open(CACHE_VERSION).then((cache) => cache.put(req, clone));
        }
        return res;
      }).catch(() => {
        // Offline fallback for navigations
        if (req.mode === 'navigate') return caches.match('./finance-tracker.html');
        return new Response('Offline', { status: 504 });
      });
    })
  );
});

// Message channel for app to talk to SW
self.addEventListener('message', (event) => {
  if (event.data === 'SKIP_WAITING') self.skipWaiting();
  if (event.data === 'CLEAR_CACHE') {
    caches.keys().then((keys) => Promise.all(keys.map((k) => caches.delete(k))));
  }
});

// Periodic background sync hook (browser-dependent)
self.addEventListener('periodicsync', (event) => {
  if (event.tag === 'finance-sync') {
    // Placeholder — would trigger a Supabase fetch in a fuller implementation
  }
});

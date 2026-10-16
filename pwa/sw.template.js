// Offline service worker. tool/build_web.mjs turns this into build/web/sw.js.
'use strict';

const VERSION = '%%VERSION%%';
const ENGINE = '%%ENGINE%%';
const PRECACHE = %%PRECACHE%%;

const APP_CACHE = `fittrack-app-${VERSION}`;
// Kept across app updates (changes only with the Flutter engine).
const ENGINE_CACHE = `fittrack-engine-${ENGINE}`;
const FONT_CACHE = 'fittrack-fonts-v1';
const FONT_HOSTS = ['fonts.gstatic.com', 'fonts.googleapis.com'];
const INDEX_URL = new URL('./', self.registration.scope).href;

self.addEventListener('install', (event) => {
  event.waitUntil(
    (async () => {
      const cache = await caches.open(APP_CACHE);
      await cache.addAll(
        PRECACHE.map((path) => new Request(new URL(path, self.registration.scope), { cache: 'reload' })),
      );
      await carryOverEngineFiles();
      await self.skipWaiting();
    })(),
  );
});

self.addEventListener('activate', (event) => {
  event.waitUntil(
    (async () => {
      const keep = new Set([APP_CACHE, ENGINE_CACHE, FONT_CACHE]);
      for (const key of await caches.keys()) {
        if (key.startsWith('fittrack-') && !keep.has(key)) await caches.delete(key);
      }
      await self.clients.claim();
    })(),
  );
});

self.addEventListener('fetch', (event) => {
  const { request } = event;
  if (request.method !== 'GET') return;
  const url = new URL(request.url);

  if (request.mode === 'navigate' && url.origin === self.location.origin) {
    // Every page load gets the cached app shell.
    event.respondWith(appShell(request));
    return;
  }
  const cacheName = cacheFor(url);
  if (cacheName) event.respondWith(cacheFirst(request, cacheName));
});

// The page sends the URLs it loaded so they work offline.
self.addEventListener('message', (event) => {
  const data = event.data || {};
  if (data.type === 'CACHE_URLS' && Array.isArray(data.urls)) {
    event.waitUntil(cacheUrls(data.urls));
  }
});

function cacheFor(url) {
  if (FONT_HOSTS.includes(url.hostname)) return FONT_CACHE;
  if (url.origin !== self.location.origin || url.pathname.endsWith('/sw.js')) return null;
  // Videos stream from the server (needs byte-range requests); thumbnails are cached.
  if (url.pathname.includes('/videos/') && !url.pathname.endsWith('.jpg')) return null;
  return url.pathname.includes('/canvaskit/') ? ENGINE_CACHE : APP_CACHE;
}

async function appShell(request) {
  const cached = await caches.match(INDEX_URL, { cacheName: APP_CACHE });
  if (cached) return cached;
  return fetch(request);
}

async function cacheFirst(request, cacheName) {
  const cache = await caches.open(cacheName);
  const cached = await cache.match(request);
  if (cached) return cached;
  const response = await fetch(request);
  if (response.ok && response.type !== 'opaque') {
    cache.put(request, response.clone()).catch(() => {});
  }
  return response;
}

async function cacheUrls(urls) {
  for (const raw of urls) {
    let url;
    try {
      url = new URL(raw);
    } catch {
      continue;
    }
    const cacheName = cacheFor(url);
    if (!cacheName) continue;
    const cache = await caches.open(cacheName);
    if (await cache.match(url.href)) continue;
    try {
      const response = await fetch(url.href);
      if (response.ok) await cache.put(url.href, response);
    } catch {
      // Retry on a later visit.
    }
  }
}

// New Flutter engine: re-download the CanvasKit files cached before.
async function carryOverEngineFiles() {
  const keys = await caches.keys();
  if (keys.includes(ENGINE_CACHE)) return;
  const urls = new Set();
  for (const key of keys.filter((k) => k.startsWith('fittrack-engine-'))) {
    const old = await caches.open(key);
    for (const request of await old.keys()) urls.add(request.url);
  }
  const cache = await caches.open(ENGINE_CACHE);
  await Promise.all(
    [...urls].map((url) => cache.add(new Request(url, { cache: 'reload' })).catch(() => {})),
  );
}

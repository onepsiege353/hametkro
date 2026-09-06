/* Hametkro PWA — service worker (network-first + fallback SPA anti-404). */
const CACHE = 'hametkro-v4';
// Chemins relatifs => résolus par rapport à ce script (/hametkro/).
const CORE = ['./', './index.html', './manifest.json', './icon-192.png', './icon-512.png', './apple-icon-180.png'];
const INDEX = './index.html';

self.addEventListener('install', (e) => {
  e.waitUntil(caches.open(CACHE).then((c) => c.addAll(CORE)).catch(() => {}));
  self.skipWaiting();
});

self.addEventListener('activate', (e) => {
  e.waitUntil(
    caches.keys().then((keys) =>
      Promise.all(keys.filter((k) => k !== CACHE).map((k) => caches.delete(k)))
    ).then(() => self.clients.claim())
  );
});

// network-first : réseau d'abord (données fraîches), cache en secours.
// Si une navigation interne renvoie la page 404 de GitHub Pages (SPA en
// sous-dossier), on sert à la place l'index de l'app (jamais de 404 à l'écran).
self.addEventListener('fetch', (e) => {
  const req = e.request;
  const url = new URL(req.url);
  if (req.method !== 'GET' || url.origin !== location.origin) return;

  e.respondWith(
    fetch(req).then((res) => {
      if (res.status === 404 && req.mode === 'navigate') {
        return caches.match(INDEX).then((hit) => {
          if (hit) return hit;
          return fetch(new URL(INDEX, location.origin));
        });
      }
      if (res.ok) {
        const copy = res.clone();
        caches.open(CACHE).then((c) => c.put(req, copy)).catch(() => {});
      }
      return res;
    }).catch(() => {
      // Hors-ligne : navigation -> index ; sinon -> cache.
      return caches.match(req).then((hit) => {
        if (hit) return hit;
        if (req.mode === 'navigate') return caches.match(INDEX);
        return Response.error();
      });
    })
  );
});

/* Hametkro PWA — service worker (network-first + fallback SPA anti-404). */
const CACHE = 'hametkro-v35';
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

// ---- Web Push : affiche une notification même quand l'app est fermée ----
self.addEventListener('push', (e) => {
  let data = { title: 'Hametkro', body: '', tag: 'hk', icon: './icon-192.png' };
  try { if (e.data) data = Object.assign(data, e.data.json()); } catch (_) {}
  e.waitUntil(
    self.registration.showNotification(data.title, {
      body: data.body || '',
      tag: data.tag || 'hk',
      icon: data.icon || './icon-192.png',
      badge: './icon-192.png',
      data: { url: (data.data && data.data.url) || './' }
    })
  );
});
self.addEventListener('notificationclick', (e) => {
  e.notification.close();
  const url = (e.notification.data && e.notification.data.url) || './';
  const full = new URL(url, location.origin).href;
  e.waitUntil(
    clients.matchAll({ type: 'window', includeUncontrolled: true }).then((list) => {
      for (const c of list) {
        if ('focus' in c && c.url === full) return c.focus();
      }
      return clients.openWindow(url);
    })
  );
});

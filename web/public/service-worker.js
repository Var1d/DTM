const CACHE_NAME = 'academic-task-manager-cache-v2';
const APP_SHELL = ['/', '/index.html', '/manifest.json', '/pio-logo.png', '/logo192.png', '/logo512.png'];

const getBuildAssets = async () => {
  try {
    const response = await fetch('/asset-manifest.json', { cache: 'no-store' });
    if (!response.ok) return [];

    const manifest = await response.json();
    return Object.values(manifest.files || {}).filter((asset) => {
      return typeof asset === 'string' && !asset.endsWith('.map');
    });
  } catch {
    return [];
  }
};

const cacheAppShell = async () => {
  const cache = await caches.open(CACHE_NAME);
  const buildAssets = await getBuildAssets();
  const urlsToCache = [...new Set([...APP_SHELL, ...buildAssets])];
  await cache.addAll(urlsToCache);
};

self.addEventListener('install', (event) => {
  event.waitUntil(cacheAppShell());
  self.skipWaiting();
});

self.addEventListener('fetch', (event) => {
  if (event.request.method !== 'GET') return;

  const requestUrl = new URL(event.request.url);
  const isNavigation = event.request.mode === 'navigate';
  const isSameOrigin = requestUrl.origin === self.location.origin;

  if (isNavigation) {
    event.respondWith(
      fetch(event.request)
        .then((response) => {
          const responseClone = response.clone();
          caches.open(CACHE_NAME).then((cache) => cache.put('/index.html', responseClone));
          return response;
        })
        .catch(() => caches.match('/index.html'))
    );
    return;
  }

  if (isSameOrigin) {
    event.respondWith(
      caches.match(event.request).then((cached) => {
        const networkFetch = fetch(event.request)
          .then((response) => {
            if (response && response.ok) {
              const responseClone = response.clone();
              caches.open(CACHE_NAME).then((cache) => cache.put(event.request, responseClone));
            }
            return response;
          })
          .catch(() => cached);

        return cached || networkFetch;
      })
    );
  }
});

self.addEventListener('activate', (event) => {
  event.waitUntil(
    caches.keys().then((keys) =>
      Promise.all(keys.filter((k) => k !== CACHE_NAME).map((k) => caches.delete(k)))
    )
  );
  self.clients.claim();
});

self.addEventListener('push', (event) => {
  let payload = {
    title: 'PIO',
    body: 'Ada notifikasi baru.',
    url: '/',
    tag: 'pio-notification',
  };

  if (event.data) {
    try {
      payload = { ...payload, ...event.data.json() };
    } catch {
      payload.body = event.data.text();
    }
  }

  event.waitUntil(
    self.registration.showNotification(payload.title, {
      body: payload.body,
      icon: '/pio-logo.png',
      badge: '/pio-logo.png',
      tag: payload.tag,
      renotify: Boolean(payload.renotify),
      data: {
        url: payload.url || '/',
        ...(payload.data || {}),
      },
    })
  );
});

self.addEventListener('notificationclick', (event) => {
  event.notification.close();
  const targetUrl = new URL(event.notification.data?.url || '/', self.location.origin).href;

  event.waitUntil(
    clients.matchAll({ type: 'window', includeUncontrolled: true }).then((clientList) => {
      for (const client of clientList) {
        if ('focus' in client) {
          client.navigate(targetUrl);
          return client.focus();
        }
      }

      if (clients.openWindow) {
        return clients.openWindow(targetUrl);
      }

      return null;
    })
  );
});

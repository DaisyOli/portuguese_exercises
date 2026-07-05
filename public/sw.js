// Practice-BR Service Worker v2 — caching estratégico para PWA

var CACHE = 'practicebr-v2';

// ── Instalação: ativa imediatamente sem esperar abas fecharem ──────────────
self.addEventListener('install', function(event) {
  self.skipWaiting();
});

// ── Ativação: apaga caches antigos e assume controle das abas abertas ──────
self.addEventListener('activate', function(event) {
  event.waitUntil(
    caches.keys().then(function(keys) {
      return Promise.all(
        keys.filter(function(k) { return k !== CACHE; })
            .map(function(k) { return caches.delete(k); })
      );
    }).then(function() { return self.clients.claim(); })
  );
});

// ── Fetch: estratégia por tipo de recurso ─────────────────────────────────
self.addEventListener('fetch', function(event) {
  var req = event.request;
  var url = new URL(req.url);

  // Ignora não-GET e requisições externas (Google Fonts, CDNs, etc.)
  if (req.method !== 'GET') return;
  if (url.origin !== self.location.origin) return;
  // Ignora o próprio SW (browser gerencia atualização)
  if (url.pathname === '/sw.js') return;

  // Cache-first: assets com fingerprint (CSS, JS, imagens em /assets/)
  // São imutáveis por definição — a URL muda quando o conteúdo muda
  if (url.pathname.startsWith('/assets/')) {
    event.respondWith(cacheFirst(req));
    return;
  }

  // Stale-while-revalidate: ícones, manifest e apple-touch-icon
  // Raramente mudam; carregar do cache e atualizar em segundo plano
  if (url.pathname.startsWith('/icons/') ||
      url.pathname === '/manifest.json' ||
      url.pathname === '/apple-touch-icon.png') {
    event.respondWith(staleWhileRevalidate(req));
    return;
  }

  // Network-first: páginas HTML (dinâmicas, dados do usuário)
  // Sempre tenta a rede; usa cache como fallback offline
  if (req.headers.get('accept') && req.headers.get('accept').includes('text/html')) {
    event.respondWith(networkFirst(req));
    return;
  }
});

// ── Estratégias ───────────────────────────────────────────────────────────

function cacheFirst(req) {
  return caches.open(CACHE).then(function(cache) {
    return cache.match(req).then(function(cached) {
      if (cached) return cached;
      return fetch(req).then(function(response) {
        if (response.ok) cache.put(req, response.clone());
        return response;
      });
    });
  });
}

function staleWhileRevalidate(req) {
  return caches.open(CACHE).then(function(cache) {
    return cache.match(req).then(function(cached) {
      var fetchPromise = fetch(req).then(function(response) {
        if (response.ok) cache.put(req, response.clone());
        return response;
      });
      return cached || fetchPromise;
    });
  });
}

function networkFirst(req) {
  return fetch(req)
    .then(function(response) {
      if (response.ok) {
        caches.open(CACHE).then(function(cache) { cache.put(req, response.clone()); });
      }
      return response;
    })
    .catch(function() {
      return caches.match(req).then(function(cached) {
        return cached || new Response('Você está offline. Abra o app com conexão.', {
          status: 503,
          headers: { 'Content-Type': 'text/plain; charset=utf-8' }
        });
      });
    });
}

// ── Push notifications (inalterado) ──────────────────────────────────────
self.addEventListener('push', function(event) {
  if (!event.data) return;
  var data = event.data.json();
  event.waitUntil(
    self.registration.showNotification(data.title, {
      body:    data.body,
      icon:    '/icons/android-chrome-192x192.png',
      badge:   '/icons/favicon-32x32.png',
      data:    { url: data.url || '/student_dashboard' },
      vibrate: [100, 50, 100]
    })
  );
});

self.addEventListener('notificationclick', function(event) {
  event.notification.close();
  var url = event.notification.data.url;
  event.waitUntil(
    clients.matchAll({ type: 'window', includeUncontrolled: true }).then(function(clientList) {
      for (var i = 0; i < clientList.length; i++) {
        if (clientList[i].url === url && 'focus' in clientList[i]) return clientList[i].focus();
      }
      if (clients.openWindow) return clients.openWindow(url);
    })
  );
});

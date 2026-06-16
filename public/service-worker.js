var CACHE_NAME = 'practice-br-v1';
var OFFLINE_URL = '/offline.html';

self.addEventListener('install', function(event) {
  event.waitUntil(
    caches.open(CACHE_NAME).then(function(cache) {
      return cache.addAll([OFFLINE_URL]);
    })
  );
  self.skipWaiting();
});

self.addEventListener('activate', function(event) {
  event.waitUntil(self.clients.claim());
});

self.addEventListener('fetch', function(event) {
  var request = event.request;
  var url = new URL(request.url);

  if (request.method !== 'GET') return;

  // Não interceptar área do professor, admin ou Active Storage
  if (url.pathname.startsWith('/teachers')) return;
  if (url.pathname.startsWith('/admin')) return;
  if (url.pathname.startsWith('/rails/active_storage')) return;

  // Somente navegações HTML: servir offline.html se a rede falhar
  if (request.mode === 'navigate') {
    event.respondWith(
      fetch(request).catch(function() {
        return caches.match(OFFLINE_URL);
      })
    );
  }
  // Assets (CSS, JS, imagens, JSON): passam normalmente, sem cache
});

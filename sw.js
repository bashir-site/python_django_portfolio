// Service Worker для агрессивного кеширования портфолио
// Версия кеша - обновляйте при изменении файлов
const CACHE_VERSION = 'portfolio-v1.0.0';
const CACHE_NAME = `portfolio-cache-${CACHE_VERSION}`;

// Критические ресурсы для кеширования при установке
const CRITICAL_ASSETS = [
  '/',
  '/index.html',
  '/assets/css/style.css',
  '/assets/css/fonts.css',
  '/assets/vendor/bootstrap/css/bootstrap.min.css',
  '/assets/vendor/bootstrap-icons/bootstrap-icons.css',
  '/assets/img/profile-img2.JPG',
  '/assets/img/hero-bg5.png',
  '/assets/img/favicon.png',
  // Локальные шрифты
  '/assets/fonts/open-sans/Regular.woff2',
  '/assets/fonts/raleway/Regular.woff2',
  '/assets/fonts/poppins/Regular.woff2',
];

// Установка Service Worker
self.addEventListener('install', (event) => {
  console.log('[SW] Installing Service Worker...');
  event.waitUntil(
    caches.open(CACHE_NAME)
      .then((cache) => {
        console.log('[SW] Caching critical assets');
        return cache.addAll(CRITICAL_ASSETS.map(url => new Request(url, { cache: 'reload' })));
      })
      .then(() => {
        // Активируем новый Service Worker сразу
        return self.skipWaiting();
      })
      .catch((error) => {
        console.error('[SW] Cache installation failed:', error);
      })
  );
});

// Активация Service Worker
self.addEventListener('activate', (event) => {
  console.log('[SW] Activating Service Worker...');
  event.waitUntil(
    caches.keys().then((cacheNames) => {
      return Promise.all(
        cacheNames.map((cacheName) => {
          // Удаляем старые кеши
          if (cacheName !== CACHE_NAME) {
            console.log('[SW] Deleting old cache:', cacheName);
            return caches.delete(cacheName);
          }
        })
      );
    }).then(() => {
      // Берем контроль над всеми страницами
      return self.clients.claim();
    })
  );
});

// Перехват запросов - стратегия Cache First для статики
self.addEventListener('fetch', (event) => {
  const { request } = event;
  const url = new URL(request.url);

  // Пропускаем внешние запросы (только для социальных сетей и внешних API)
  if (url.origin !== location.origin) {
    return;
  }

  // Стратегия Cache First для статических ресурсов
  if (request.destination === 'image' || 
      request.destination === 'style' || 
      request.destination === 'script' ||
      request.destination === 'font' ||
      url.pathname.match(/\.(jpg|jpeg|png|gif|ico|css|js|svg|woff|woff2|ttf|eot|otf|webp)$/)) {
    
    event.respondWith(
      caches.match(request)
        .then((cachedResponse) => {
          if (cachedResponse) {
            // Возвращаем из кеша
            return cachedResponse;
          }
          
          // Если нет в кеше, загружаем из сети и кешируем
          return fetch(request)
            .then((response) => {
              // Клонируем ответ для кеширования
              const responseToCache = response.clone();
              
              caches.open(CACHE_NAME).then((cache) => {
                cache.put(request, responseToCache);
              });
              
              return response;
            })
            .catch(() => {
              // Если сеть недоступна, возвращаем fallback
              if (request.destination === 'image') {
                return new Response('', { status: 200, statusText: 'OK' });
              }
            });
        })
    );
  }
  // Для HTML используем Network First с fallback на кеш
  else if (request.destination === 'document' || url.pathname.endsWith('.html')) {
    event.respondWith(
      fetch(request)
        .then((response) => {
          // Клонируем и кешируем успешные ответы
          const responseToCache = response.clone();
          caches.open(CACHE_NAME).then((cache) => {
            cache.put(request, responseToCache);
          });
          return response;
        })
        .catch(() => {
          // Если сеть недоступна, используем кеш
          return caches.match(request).then((cachedResponse) => {
            return cachedResponse || caches.match('/index.html');
          });
        })
    );
  }
});

// Сообщения от клиента для обновления кеша
self.addEventListener('message', (event) => {
  if (event.data && event.data.type === 'SKIP_WAITING') {
    self.skipWaiting();
  }
  
  if (event.data && event.data.type === 'CLEAR_CACHE') {
    caches.delete(CACHE_NAME).then(() => {
      console.log('[SW] Cache cleared');
    });
  }
});

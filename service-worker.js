const CACHE_NAME = "service-k38-v11";
const LOCAL_ASSETS = [
  "./",
  "./index.html",
  "./config.js",
  "./logo-k38.png",
  "./icon-192.png",
  "./icon-512.png",
  "./manifest.webmanifest",
  "./sound-click.wav",
  "./sound-success.wav",
  "./sound-error.wav"
];

self.addEventListener("install", event => {
  event.waitUntil(caches.open(CACHE_NAME).then(cache => cache.addAll(LOCAL_ASSETS)));
  self.skipWaiting();
});

self.addEventListener("activate", event => {
  event.waitUntil(
    caches.keys().then(keys =>
      Promise.all(keys.filter(key => key !== CACHE_NAME).map(key => caches.delete(key)))
    ).then(() => self.clients.claim())
  );
});

self.addEventListener("fetch", event => {
  event.respondWith(
    caches.match(event.request).then(cached => {
      if (cached) return cached;
      return fetch(event.request).catch(() => {
        if (event.request.mode === "navigate") return caches.match("./index.html");
      });
    })
  );
});

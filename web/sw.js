const CACHE = "joris-shell-v110";
const SHELL = [
  "/",
  "/index.html",
  "/styles.css",
  "/styles.css?v=82",
  "/app.js",
  "/app.js?v=64",
  "/manifest.webmanifest",
  "/favicon.ico?v=play1",
  "/youtube-logo.png",
  "/go.jpg",
  "/icon-180.png?v=go1",
  "/icon-512.png"
];

self.addEventListener("install", (event) => {
  event.waitUntil(
    caches.open(CACHE).then((cache) => cache.addAll(SHELL)).then(() => self.skipWaiting())
  );
});

self.addEventListener("activate", (event) => {
  event.waitUntil(
    caches.keys()
      .then((keys) => Promise.all(keys.filter((key) => key !== CACHE).map((key) => caches.delete(key))))
      .then(() => self.clients.claim())
  );
});

self.addEventListener("fetch", (event) => {
  const url = new URL(event.request.url);
  if (url.origin !== self.location.origin) return;
  if (url.pathname.startsWith("/music/") || url.pathname.startsWith("/api/") || url.pathname === "/catalog.json") {
    return;
  }

  event.respondWith(
    fetch(new Request(event.request, { cache: "no-cache" }))
      .then((response) => {
        if (response.ok && event.request.method === "GET") {
          const copy = response.clone();
          caches.open(CACHE).then((cache) => cache.put(event.request, copy));
        }
        return response;
      })
      .catch(async () => {
        const cached = await caches.match(event.request);
        if (cached) return cached;
        if (event.request.mode === "navigate") {
          return (await caches.match("/index.html")) || (await caches.match("/"));
        }
        return new Response("Offline", { status: 503, statusText: "Offline" });
      })
  );
});

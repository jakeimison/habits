const C="habits-v14",F=["./","index.html","config.js","manifest.webmanifest","icon-180.png","icon-192.png","icon-512.png"];
self.addEventListener("install",e=>{e.waitUntil(caches.open(C).then(c=>c.addAll(F)));self.skipWaiting()});
self.addEventListener("activate",e=>{e.waitUntil(caches.keys().then(k=>Promise.all(k.filter(x=>x!==C).map(x=>caches.delete(x)))));self.clients.claim()});
// Network first (so new uploads show up on the next open), cache as offline fallback.
// Leaderboard/account requests to Supabase are never cached.
self.addEventListener("fetch",e=>{
  if(e.request.method!=="GET")return;
  const u=new URL(e.request.url);if(u.hostname.endsWith("supabase.co")||u.hostname.endsWith("supabase.in"))return;
  const same=u.origin===location.origin;
  e.respondWith(fetch(e.request,same?{cache:"no-store"}:{}).then(r=>{const cp=r.clone();caches.open(C).then(c=>c.put(e.request,cp));return r}).catch(()=>caches.match(e.request,{ignoreSearch:true})));
});

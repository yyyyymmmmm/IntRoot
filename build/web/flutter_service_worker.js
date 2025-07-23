'use strict';
const MANIFEST = 'flutter-app-manifest';
const TEMP = 'flutter-temp-cache';
const CACHE_NAME = 'flutter-app-cache';

const RESOURCES = {"assets/AssetManifest.bin": "9295f06e56e8967ad35dc93cc4223c0d",
"assets/AssetManifest.bin.json": "908270a505fd1f0c32a36803a95102d3",
"assets/AssetManifest.json": "d3febac8049e53e5bb1f798ddce80ea0",
"assets/assets/fonts/SF-Mono-Regular.ttf": "5715d3f0bfcd28a4e008721a66118fe2",
"assets/assets/fonts/SF-Pro-Display-Bold.ttf": "299556cecd6b730bce8230f529e837a1",
"assets/assets/fonts/SF-Pro-Display-Light.ttf": "d44929d62a49114d494d1768893fcdf7",
"assets/assets/fonts/SF-Pro-Display-Medium.ttf": "426088e434f43481b24859270171b906",
"assets/assets/fonts/SF-Pro-Display-Regular.ttf": "d9076ed73f2501090da92fe3c72d3ce6",
"assets/assets/images/black2logo.png": "4124bc9b6c9ae8feebfe3794ef9e45e6",
"assets/assets/images/logo.png": "07f3861c64be3593cedba67021a647f0",
"assets/assets/images/onboarding/notes_icon.svg": "39ba5a753cb80a204e2d6a44718ad2e9",
"assets/assets/images/onboarding/workspace.png": "1c52960754ee13bf5b1f57dfc7f76203",
"assets/FontManifest.json": "1c3a8c867b011fe235f4cbecfbb99dc6",
"assets/fonts/MaterialIcons-Regular.otf": "c36229d19f481c83320433e7b7ce78bb",
"assets/NOTICES": "c2300d696402383b2267d3cc08e58c10",
"assets/packages/cupertino_icons/assets/CupertinoIcons.ttf": "33b7d9392238c04c131b6ce224e13711",
"assets/shaders/ink_sparkle.frag": "ecc85a2e95f5e9f53123dcaf8cb9b6ce",
"canvaskit/canvaskit.js": "728b2d477d9b8c14593d4f9b82b484f3",
"canvaskit/canvaskit.js.symbols": "bdcd3835edf8586b6d6edfce8749fb77",
"canvaskit/canvaskit.wasm": "7a3f4ae7d65fc1de6a6e7ddd3224bc93",
"canvaskit/chromium/canvaskit.js": "8191e843020c832c9cf8852a4b909d4c",
"canvaskit/chromium/canvaskit.js.symbols": "b61b5f4673c9698029fa0a746a9ad581",
"canvaskit/chromium/canvaskit.wasm": "f504de372e31c8031018a9ec0a9ef5f0",
"canvaskit/skwasm.js": "ea559890a088fe28b4ddf70e17e60052",
"canvaskit/skwasm.js.symbols": "e72c79950c8a8483d826a7f0560573a1",
"canvaskit/skwasm.wasm": "39dd80367a4e71582d234948adc521c0",
"favicon.png": "c07b91320419aa3cc35a3e1aca3e7be5",
"flutter.js": "83d881c1dbb6d6bcd6b42e274605b69c",
"flutter_bootstrap.js": "6605c2be5eea68af34b57f14063b27c8",
"icons/Icon-192.png": "93b5bbcfb57f906f07d55419e99aff37",
"icons/Icon-512.png": "14a5b3bcd1e3d605fbee0ce92f13cf9d",
"icons/Icon-maskable-192.png": "93b5bbcfb57f906f07d55419e99aff37",
"icons/Icon-maskable-512.png": "14a5b3bcd1e3d605fbee0ce92f13cf9d",
"index.html": "b1b554db42bfe99a726d0c12afd4f037",
"/": "b1b554db42bfe99a726d0c12afd4f037",
"main.dart.js": "646f03dcb3125be86ba09f8e1bb3984c",
"manifest.json": "8fe0bd39abfaa94ede3f5d442de81664",
"splash/img/dark-1x.png": "a61d7d0828fe2e635b76d9b07cce082b",
"splash/img/dark-2x.png": "eaf6f63aad06140822118156140d787d",
"splash/img/dark-3x.png": "810845fedd3efa18d8862f18568394bb",
"splash/img/dark-4x.png": "14a5b3bcd1e3d605fbee0ce92f13cf9d",
"splash/img/light-1x.png": "a61d7d0828fe2e635b76d9b07cce082b",
"splash/img/light-2x.png": "eaf6f63aad06140822118156140d787d",
"splash/img/light-3x.png": "810845fedd3efa18d8862f18568394bb",
"splash/img/light-4x.png": "14a5b3bcd1e3d605fbee0ce92f13cf9d",
"version.json": "e9c6b5cd23d61eaf997b81089005741c"};
// The application shell files that are downloaded before a service worker can
// start.
const CORE = ["main.dart.js",
"index.html",
"flutter_bootstrap.js",
"assets/AssetManifest.bin.json",
"assets/FontManifest.json"];

// During install, the TEMP cache is populated with the application shell files.
self.addEventListener("install", (event) => {
  self.skipWaiting();
  return event.waitUntil(
    caches.open(TEMP).then((cache) => {
      return cache.addAll(
        CORE.map((value) => new Request(value, {'cache': 'reload'})));
    })
  );
});
// During activate, the cache is populated with the temp files downloaded in
// install. If this service worker is upgrading from one with a saved
// MANIFEST, then use this to retain unchanged resource files.
self.addEventListener("activate", function(event) {
  return event.waitUntil(async function() {
    try {
      var contentCache = await caches.open(CACHE_NAME);
      var tempCache = await caches.open(TEMP);
      var manifestCache = await caches.open(MANIFEST);
      var manifest = await manifestCache.match('manifest');
      // When there is no prior manifest, clear the entire cache.
      if (!manifest) {
        await caches.delete(CACHE_NAME);
        contentCache = await caches.open(CACHE_NAME);
        for (var request of await tempCache.keys()) {
          var response = await tempCache.match(request);
          await contentCache.put(request, response);
        }
        await caches.delete(TEMP);
        // Save the manifest to make future upgrades efficient.
        await manifestCache.put('manifest', new Response(JSON.stringify(RESOURCES)));
        // Claim client to enable caching on first launch
        self.clients.claim();
        return;
      }
      var oldManifest = await manifest.json();
      var origin = self.location.origin;
      for (var request of await contentCache.keys()) {
        var key = request.url.substring(origin.length + 1);
        if (key == "") {
          key = "/";
        }
        // If a resource from the old manifest is not in the new cache, or if
        // the MD5 sum has changed, delete it. Otherwise the resource is left
        // in the cache and can be reused by the new service worker.
        if (!RESOURCES[key] || RESOURCES[key] != oldManifest[key]) {
          await contentCache.delete(request);
        }
      }
      // Populate the cache with the app shell TEMP files, potentially overwriting
      // cache files preserved above.
      for (var request of await tempCache.keys()) {
        var response = await tempCache.match(request);
        await contentCache.put(request, response);
      }
      await caches.delete(TEMP);
      // Save the manifest to make future upgrades efficient.
      await manifestCache.put('manifest', new Response(JSON.stringify(RESOURCES)));
      // Claim client to enable caching on first launch
      self.clients.claim();
      return;
    } catch (err) {
      // On an unhandled exception the state of the cache cannot be guaranteed.
      console.error('Failed to upgrade service worker: ' + err);
      await caches.delete(CACHE_NAME);
      await caches.delete(TEMP);
      await caches.delete(MANIFEST);
    }
  }());
});
// The fetch handler redirects requests for RESOURCE files to the service
// worker cache.
self.addEventListener("fetch", (event) => {
  if (event.request.method !== 'GET') {
    return;
  }
  var origin = self.location.origin;
  var key = event.request.url.substring(origin.length + 1);
  // Redirect URLs to the index.html
  if (key.indexOf('?v=') != -1) {
    key = key.split('?v=')[0];
  }
  if (event.request.url == origin || event.request.url.startsWith(origin + '/#') || key == '') {
    key = '/';
  }
  // If the URL is not the RESOURCE list then return to signal that the
  // browser should take over.
  if (!RESOURCES[key]) {
    return;
  }
  // If the URL is the index.html, perform an online-first request.
  if (key == '/') {
    return onlineFirst(event);
  }
  event.respondWith(caches.open(CACHE_NAME)
    .then((cache) =>  {
      return cache.match(event.request).then((response) => {
        // Either respond with the cached resource, or perform a fetch and
        // lazily populate the cache only if the resource was successfully fetched.
        return response || fetch(event.request).then((response) => {
          if (response && Boolean(response.ok)) {
            cache.put(event.request, response.clone());
          }
          return response;
        });
      })
    })
  );
});
self.addEventListener('message', (event) => {
  // SkipWaiting can be used to immediately activate a waiting service worker.
  // This will also require a page refresh triggered by the main worker.
  if (event.data === 'skipWaiting') {
    self.skipWaiting();
    return;
  }
  if (event.data === 'downloadOffline') {
    downloadOffline();
    return;
  }
});
// Download offline will check the RESOURCES for all files not in the cache
// and populate them.
async function downloadOffline() {
  var resources = [];
  var contentCache = await caches.open(CACHE_NAME);
  var currentContent = {};
  for (var request of await contentCache.keys()) {
    var key = request.url.substring(origin.length + 1);
    if (key == "") {
      key = "/";
    }
    currentContent[key] = true;
  }
  for (var resourceKey of Object.keys(RESOURCES)) {
    if (!currentContent[resourceKey]) {
      resources.push(resourceKey);
    }
  }
  return contentCache.addAll(resources);
}
// Attempt to download the resource online before falling back to
// the offline cache.
function onlineFirst(event) {
  return event.respondWith(
    fetch(event.request).then((response) => {
      return caches.open(CACHE_NAME).then((cache) => {
        cache.put(event.request, response.clone());
        return response;
      });
    }).catch((error) => {
      return caches.open(CACHE_NAME).then((cache) => {
        return cache.match(event.request).then((response) => {
          if (response != null) {
            return response;
          }
          throw error;
        });
      });
    })
  );
}

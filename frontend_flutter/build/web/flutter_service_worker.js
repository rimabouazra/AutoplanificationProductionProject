'use strict';
const MANIFEST = 'flutter-app-manifest';
const TEMP = 'flutter-temp-cache';
const CACHE_NAME = 'flutter-app-cache';

const RESOURCES = {"assets/AssetManifest.bin": "fba2957c059519f5219e448ae05dd044",
"assets/AssetManifest.bin.json": "bdf8fb083df78c4ee5f845aab2e219b6",
"assets/AssetManifest.json": "2577bb4642a309c886eebb8fa3ed4a3c",
"assets/assets/auth_bg.jpeg": "d3ba42f9b0bd647222b71eea610ef8d8",
"assets/assets/fonts/PlayfairDisplay-Bold.ttf": "9b38798112efb7cf6eca1de031cec4ca",
"assets/assets/fonts/PlayfairDisplay-Regular.ttf": "1a28efdbd2876d90e554a67faabad24b",
"assets/assets/fonts/Roboto.ttf": "7d752fb726f5ece291e2e522fcecf86d",
"assets/assets/icons/dashboard.png": "74c517c8d8e2d3557e5a19a589026771",
"assets/assets/icons/orders.png": "281911831e4122721a3ba687ef4094b3",
"assets/assets/icons/planning.png": "525ba3dc0ea5a23a32a8483c3fe72e68",
"assets/assets/icons/rooms.png": "d1d6dea5c49801220474d50bfc60dff4",
"assets/assets/icons/stock.png": "c5fac0d32b02147dee7a765cb24a4c67",
"assets/assets/icons/users.png": "4601f773e41c094849e10288a7aec5e8",
"assets/assets/images/About.jpg": "32dd891db29d8387b0c3a02c80809b76",
"assets/assets/images/BALCONNET.jpg": "f4c976832f63cdbd1b4682be88434d3e",
"assets/assets/images/BANDEAU.jpg": "000ed210f3ed1479d2b21e40061b03d6",
"assets/assets/images/BIG-SIZES.jpg": "a98d59e5a450140ebd752fa478c8325d",
"assets/assets/images/bigPanel.jpg": "32d37c02b2268b8cdc3cdc42467802f7",
"assets/assets/images/bra-cup-1.jpg": "bc33b06c37b9a5d59ca50c9bad47f7e4",
"assets/assets/images/braCup.jpg": "b9143039a37bf97f28e7fdadccc66914",
"assets/assets/images/COMFORT-BRA-CUP.jpg": "7124a671ead69416684623125e844372",
"assets/assets/images/coque.jpg": "7124a671ead69416684623125e844372",
"assets/assets/images/ECO-FRIENDLY-BRA-CUP.jpg": "f4e026588cbb80446a34d5c315be20c9",
"assets/assets/images/hero1.jpg": "97ddf64bd5a063b5688c0e2617492b98",
"assets/assets/images/hero2.jpg": "25ae978a51f8ca2d9cdef059240cd510",
"assets/assets/images/hero3.jpg": "5519bcbefa7cf131f90d2b7a68ed9f59",
"assets/assets/images/login_illustration.svg": "a60654ff4c57ec5b3db19b1560aad18f",
"assets/assets/images/logo.jpg": "577a4054587a2612a6e06df31d7a7156",
"assets/assets/images/push-up.jpg": "c8bb77bbb5f3522155a3c40f1c8ed36d",
"assets/assets/images/register_illustration.svg": "fbc28ffcb45c241f30e539c48586873c",
"assets/assets/images/TRIANGLE.jpg": "b6a4890619c8c599a32916aa4af3cc24",
"assets/assets/images/trianglePushUp.jpg": "afb7e2838cb110caba1391f84064515b",
"assets/assets/logo.jpg": "577a4054587a2612a6e06df31d7a7156",
"assets/FontManifest.json": "36fc9975a60b4343b3ee944204847f83",
"assets/fonts/MaterialIcons-Regular.otf": "f5918dac7a51fc760dbefba26b597ee8",
"assets/NOTICES": "d951b11ad2b1e6526edf229efd481b13",
"assets/packages/cupertino_icons/assets/CupertinoIcons.ttf": "33b7d9392238c04c131b6ce224e13711",
"assets/packages/fluttertoast/assets/toastify.css": "a85675050054f179444bc5ad70ffc635",
"assets/packages/fluttertoast/assets/toastify.js": "56e2c9cedd97f10e7e5f1cebd85d53e3",
"assets/packages/flutter_charts/google_fonts/Comforter-Regular.ttf": "cff123ea94f9032380183b8bbbf30ec1",
"assets/shaders/ink_sparkle.frag": "ecc85a2e95f5e9f53123dcaf8cb9b6ce",
"canvaskit/canvaskit.js": "86e461cf471c1640fd2b461ece4589df",
"canvaskit/canvaskit.js.symbols": "68eb703b9a609baef8ee0e413b442f33",
"canvaskit/canvaskit.wasm": "efeeba7dcc952dae57870d4df3111fad",
"canvaskit/chromium/canvaskit.js": "34beda9f39eb7d992d46125ca868dc61",
"canvaskit/chromium/canvaskit.js.symbols": "5a23598a2a8efd18ec3b60de5d28af8f",
"canvaskit/chromium/canvaskit.wasm": "64a386c87532ae52ae041d18a32a3635",
"canvaskit/skwasm.js": "f2ad9363618c5f62e813740099a80e63",
"canvaskit/skwasm.js.symbols": "80806576fa1056b43dd6d0b445b4b6f7",
"canvaskit/skwasm.wasm": "f0dfd99007f989368db17c9abeed5a49",
"canvaskit/skwasm_st.js": "d1326ceef381ad382ab492ba5d96f04d",
"canvaskit/skwasm_st.js.symbols": "c7e7aac7cd8b612defd62b43e3050bdd",
"canvaskit/skwasm_st.wasm": "56c3973560dfcbf28ce47cebe40f3206",
"favicon.png": "5dcef449791fa27946b3d35ad8803796",
"flutter.js": "76f08d47ff9f5715220992f993002504",
"flutter_bootstrap.js": "c1e5025b762dea382314d744ef56b726",
"icons/Icon-192.png": "ac9a721a12bbc803b44f645561ecb1e1",
"icons/Icon-512.png": "96e752610906ba2a93c65f8abe1645f1",
"icons/Icon-maskable-192.png": "c457ef57daa1d16f64b27b786ec2ea3c",
"icons/Icon-maskable-512.png": "301a7604d45b3e739efc881eb04896ea",
"index.html": "9f958814e7e66272f89bf4576c7f6bc8",
"/": "9f958814e7e66272f89bf4576c7f6bc8",
"main.dart.js": "3d0817ce85d992310cc0b73d029dfe70",
"manifest.json": "0030ff64be1c3181710c3014b11018a8",
"version.json": "2b521e10dfa0f067561de489a19d6620"};
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

/**
 * Append this to flutter_service_worker.js after build so push works when app is closed.
 * Run: node scripts/append_push_to_sw.js (or the PowerShell equivalent from repo root).
 */
self.addEventListener('push', function (event) {
  var data = { title: 'Club Blackout', body: 'Something happened in the game.' };
  try {
    if (event.data) {
      var json = event.data.json();
      if (json.title) data.title = json.title;
      if (json.body) data.body = json.body;
      if (json.tag) data.tag = json.tag;
    }
  } catch (_) {}
  event.waitUntil(
    self.registration.showNotification(data.title, {
      body: data.body,
      tag: data.tag || 'cb-push',
      icon: '/icons/Icon-192.png',
      badge: '/icons/Icon-192.png',
      data: { url: self.location.origin + '/' }
    })
  );
});

self.addEventListener('notificationclick', function (event) {
  event.notification.close();
  var url = event.notification.data && event.notification.data.url;
  if (url) {
    event.waitUntil(
      self.clients.matchAll({ type: 'window', includeUncontrolled: true }).then(function (clientList) {
        for (var i = 0; i < clientList.length; i++) {
          if (clientList[i].url.indexOf(self.location.origin) === 0 && 'focus' in clientList[i]) {
            clientList[i].focus();
            return;
          }
        }
        if (self.clients.openWindow) return self.clients.openWindow(url);
      })
    );
  }
});

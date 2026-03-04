// Club Blackout — Push notification service worker.
// Registered alongside Flutter's own service worker.
// Handles incoming push events and notification click routing.

self.addEventListener('push', (event) => {
  if (!event.data) return;

  let payload;
  try {
    payload = event.data.json();
  } catch (_) {
    payload = { title: 'Club Blackout', body: event.data.text() };
  }

  const title = payload.notification?.title ?? payload.title ?? 'Club Blackout';
  const body = payload.notification?.body ?? payload.body ?? '';
  const icon = payload.notification?.icon ?? '/icons/Icon-192.png';
  const badge = '/icons/Icon-192.png';
  const tag = payload.data?.tag ?? 'cb-default';
  const data = payload.data ?? {};

  event.waitUntil(
    self.registration.showNotification(title, { body, icon, badge, tag, data })
  );
});

self.addEventListener('notificationclick', (event) => {
  event.notification.close();

  const url = event.notification.data?.url ?? '/';

  event.waitUntil(
    clients.matchAll({ type: 'window', includeUncontrolled: true }).then((windowClients) => {
      for (const client of windowClients) {
        if (client.url.includes(self.location.origin) && 'focus' in client) {
          return client.focus();
        }
      }
      return clients.openWindow(url);
    })
  );
});

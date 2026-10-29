/**
 * Dev safety: a previously installed production Workbox/PWA SW will intercept
 * Vite HMR URLs (/@vite/client, /src/*, /@react-refresh) and spam the console.
 * Always unregister service workers while running `npm run dev`.
 */
export async function unregisterServiceWorkersInDev(): Promise<void> {
  if (!import.meta.env.DEV) return;
  if (typeof navigator === 'undefined' || !('serviceWorker' in navigator)) {
    return;
  }

  try {
    const registrations = await navigator.serviceWorker.getRegistrations();
    await Promise.all(
      registrations.map(async (registration) => {
        const ok = await registration.unregister();
        if (ok && import.meta.env.DEV) {
          console.info(
            '[dev] Unregistered service worker:',
            registration.scope,
          );
        }
      }),
    );

    if ('caches' in window) {
      const keys = await caches.keys();
      await Promise.all(
        keys
          .filter(
            (key) =>
              key.includes('workbox') ||
              key.includes('naethra-ems') ||
              key.startsWith('sw-') ||
              key.includes('precache'),
          )
          .map((key) => caches.delete(key)),
      );
    }
  } catch (error) {
    console.warn('[dev] Failed to unregister service workers:', error);
  }
}

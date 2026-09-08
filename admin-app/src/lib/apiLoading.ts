/**
 * Bridges axios API calls to the global LoadingProvider overlay.
 */

type LoadingCallback = (loading: boolean) => void;

const loadingCallbacks = new Set<LoadingCallback>();
let activeRequests = 0;

export function registerLoadingCallback(callback: LoadingCallback) {
  loadingCallbacks.add(callback);
  return () => {
    loadingCallbacks.delete(callback);
  };
}

function notify(loading: boolean) {
  loadingCallbacks.forEach((cb) => cb(loading));
}

export function startApiLoading() {
  activeRequests += 1;
  if (activeRequests === 1) {
    notify(true);
  }
}

export function stopApiLoading() {
  activeRequests = Math.max(0, activeRequests - 1);
  if (activeRequests === 0) {
    notify(false);
  }
}

export function resetApiLoading() {
  activeRequests = 0;
  notify(false);
}

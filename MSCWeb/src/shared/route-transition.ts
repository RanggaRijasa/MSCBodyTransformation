const shellRouteStorageKey = "msc-shell-route";
const shellRouteFocusRequestKey = "msc-shell-focus-request";

export function currentBrowserRouteKey() {
  return `${window.location.pathname}?${new URLSearchParams(window.location.search).toString()}`;
}

export function readShellRouteMarker() {
  try {
    return sessionStorage.getItem(shellRouteStorageKey);
  } catch {
    return null;
  }
}

export function writeShellRouteMarker(routeKey: string) {
  try {
    sessionStorage.setItem(shellRouteStorageKey, routeKey);
  } catch {
    // Browser privacy modes may deny storage; route focus still works in-memory.
  }
}

export function requestShellRouteFocus(routeKey: string) {
  try {
    sessionStorage.setItem(shellRouteFocusRequestKey, routeKey);
  } catch {
    // Browser privacy modes may deny storage; the normal focus heuristic remains active.
  }
}

export function readShellRouteFocusRequest(routeKey: string) {
  try {
    return sessionStorage.getItem(shellRouteFocusRequestKey) === routeKey;
  } catch {
    return false;
  }
}

export function clearShellRouteFocusRequest(routeKey: string) {
  try {
    if (sessionStorage.getItem(shellRouteFocusRequestKey) === routeKey) {
      sessionStorage.removeItem(shellRouteFocusRequestKey);
    }
  } catch {
    // Browser privacy modes may deny storage; there is no request to clear.
  }
}

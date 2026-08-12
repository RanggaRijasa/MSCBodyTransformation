import { useMemo, useSyncExternalStore } from "react";

function subscribeToNavigation(onChange: () => void) {
  window.addEventListener("popstate", onChange);
  window.addEventListener("msc:navigation", onChange);
  return () => {
    window.removeEventListener("popstate", onChange);
    window.removeEventListener("msc:navigation", onChange);
  };
}

function currentPathname() {
  return typeof window === "undefined" ? "/" : window.location.pathname;
}

function currentSearch() {
  return typeof window === "undefined" ? "" : window.location.search;
}

export function usePathname() {
  return useSyncExternalStore(subscribeToNavigation, currentPathname, () => "/");
}

export function useSearchParams() {
  const search = useSyncExternalStore(subscribeToNavigation, currentSearch, () => "");
  return useMemo(() => new URLSearchParams(search), [search]);
}

export function useRouter() {
  const navigate = (href: string, mode: "push" | "replace") => {
    window.history[mode === "push" ? "pushState" : "replaceState"]({}, "", href);
    window.dispatchEvent(new Event("msc:navigation"));
    window.scrollTo({ left: 0, top: 0 });
  };
  return {
    push: (href: string) => navigate(href, "push"),
    refresh: () => window.dispatchEvent(new Event("msc:navigation")),
    replace: (href: string) => navigate(href, "replace"),
  };
}

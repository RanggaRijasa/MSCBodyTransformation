import type { AnchorHTMLAttributes, MouseEvent, ReactNode } from "react";

type DevelopmentLinkProperties = Readonly<
  Omit<AnchorHTMLAttributes<HTMLAnchorElement>, "href"> & {
    children: ReactNode;
    href: string;
  }
>;

export default function DevelopmentLink({
  children,
  href,
  onClick,
  ...properties
}: DevelopmentLinkProperties) {
  function navigate(event: MouseEvent<HTMLAnchorElement>) {
    onClick?.(event);
    if (
      event.defaultPrevented ||
      event.button !== 0 ||
      event.metaKey ||
      event.ctrlKey ||
      event.shiftKey ||
      event.altKey ||
      document.documentElement.dataset.mscRoleSimulator !== "true" ||
      !href.startsWith("/") ||
      href.startsWith("//")
    )
      return;

    event.preventDefault();
    window.history.pushState({}, "", href);
    window.dispatchEvent(new Event("msc:navigation"));
    window.scrollTo({ left: 0, top: 0 });
  }

  return (
    <a {...properties} href={href} onClick={navigate}>
      {children}
    </a>
  );
}

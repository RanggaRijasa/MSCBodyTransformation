import type { AnchorHTMLAttributes, ReactNode } from "react";

type DevelopmentLinkProperties = Readonly<
  Omit<AnchorHTMLAttributes<HTMLAnchorElement>, "href"> & {
    children: ReactNode;
    href: string;
  }
>;

export default function DevelopmentLink({
  children,
  href,
  ...properties
}: DevelopmentLinkProperties) {
  return (
    <a {...properties} href={href}>
      {children}
    </a>
  );
}

"use client";

import Link from "next/link";
import { usePathname } from "next/navigation";

import type { ShellKind, ShellNavigationItem } from "@/features/app-shell/model/navigation-items";
import { saveShellScrollPosition } from "@/features/app-shell/components/route-behavior";
import { AppIcon } from "@/shared/ui/icons/app-icon";

type ShellNavigationProperties = Readonly<{
  items: readonly ShellNavigationItem[];
  kind: ShellKind;
  label: string;
}>;

export function isNavigationItemActive(pathname: string, item: ShellNavigationItem): boolean {
  if (item.exact) return pathname === item.href;
  return pathname === item.href || pathname.startsWith(`${item.href}/`);
}

export function ShellNavigation({ items, kind, label }: ShellNavigationProperties) {
  const pathname = usePathname();

  return (
    <nav aria-label={label} className={`shell-navigation shell-navigation--${kind}`}>
      <ul>
        {items.map((item) => {
          const isActive = isNavigationItemActive(pathname, item);
          return (
            <li key={item.href}>
              <Link
                aria-current={isActive ? "page" : undefined}
                href={item.href}
                onClick={() => saveShellScrollPosition(pathname)}
              >
                <AppIcon name={item.icon} />
                <span>{item.label}</span>
              </Link>
            </li>
          );
        })}
      </ul>
    </nav>
  );
}

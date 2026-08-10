import Link from "next/link";
import type { ButtonHTMLAttributes, ReactNode } from "react";

import { AppIcon, type AppIconName } from "@/shared/ui/icons/app-icon";

export type ActionVariant = "primary" | "secondary" | "accent" | "destructive";

type AppButtonProperties = Readonly<
  ButtonHTMLAttributes<HTMLButtonElement> & {
    children: ReactNode;
    icon?: AppIconName;
    isLoading?: boolean;
    variant?: ActionVariant;
  }
>;

export function AppButton({
  children,
  className = "",
  disabled,
  icon,
  isLoading = false,
  type = "button",
  variant = "primary",
  ...properties
}: AppButtonProperties) {
  return (
    <button
      {...properties}
      aria-busy={isLoading || undefined}
      className={`app-action app-action--${variant} ${className}`.trim()}
      disabled={disabled || isLoading}
      type={type}
    >
      {isLoading ? <span aria-hidden="true" className="app-spinner" /> : null}
      {!isLoading && icon ? <AppIcon className="app-action__icon" name={icon} /> : null}
      <span>{children}</span>
    </button>
  );
}

type AppLinkProperties = Readonly<{
  children: ReactNode;
  className?: string;
  href: string;
  icon?: AppIconName;
  variant?: ActionVariant;
}>;

export function AppLink({
  children,
  className = "",
  href,
  icon,
  variant = "primary",
}: AppLinkProperties) {
  return (
    <Link className={`app-action app-action--${variant} ${className}`.trim()} href={href}>
      {icon ? <AppIcon className="app-action__icon" name={icon} /> : null}
      <span>{children}</span>
    </Link>
  );
}

type IconButtonProperties = Readonly<
  Omit<ButtonHTMLAttributes<HTMLButtonElement>, "children"> & {
    icon: AppIconName;
    label: string;
  }
>;

export function IconButton({
  className = "",
  icon,
  label,
  type = "button",
  ...properties
}: IconButtonProperties) {
  return (
    <button
      {...properties}
      aria-label={label}
      className={`icon-button ${className}`.trim()}
      type={type}
    >
      <AppIcon name={icon} />
    </button>
  );
}

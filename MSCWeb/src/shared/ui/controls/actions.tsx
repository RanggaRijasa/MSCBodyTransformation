import Link from "next/link";
import type { ButtonHTMLAttributes, ReactNode } from "react";

import { AppIcon, type AppIconName } from "@/shared/ui/icons/app-icon";
import { cn } from "@/shared/ui/lib/cn";
import { Button, buttonVariants } from "@/shared/ui/primitives/button";

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
    <Button
      {...properties}
      aria-busy={isLoading || undefined}
      className={cn("app-action", `app-action--${variant}`, className)}
      disabled={disabled || isLoading}
      type={type}
      variant={variant}
    >
      {isLoading ? <span aria-hidden="true" className="app-spinner" /> : null}
      {!isLoading && icon ? <AppIcon className="app-action__icon" name={icon} /> : null}
      <span>{children}</span>
    </Button>
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
    <Link
      className={cn(buttonVariants({ variant }), "app-action", `app-action--${variant}`, className)}
      href={href}
    >
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
    <Button
      {...properties}
      aria-label={label}
      className={cn("icon-button", className)}
      size="icon"
      type={type}
      variant="secondary"
    >
      <AppIcon name={icon} />
    </Button>
  );
}

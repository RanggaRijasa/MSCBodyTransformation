import Link from "next/link";
import type { ReactNode } from "react";

import { AppIcon, type AppIconName } from "@/shared/ui/icons/app-icon";

type SurfaceProperties = Readonly<{
  children: ReactNode;
  className?: string;
  elevated?: boolean;
}>;

export function Surface({ children, className = "", elevated = false }: SurfaceProperties) {
  return (
    <section
      className={`app-surface ${elevated ? "app-surface--elevated" : ""} ${className}`.trim()}
    >
      {children}
    </section>
  );
}

type ListRowProperties = Readonly<{
  detail?: string;
  href?: string;
  icon?: AppIconName;
  title: string;
  trailing?: ReactNode;
}>;

export function ListRow({ detail, href, icon, title, trailing }: ListRowProperties) {
  const content = (
    <>
      {icon ? (
        <span className="list-row__icon">
          <AppIcon name={icon} />
        </span>
      ) : null}
      <span className="list-row__copy">
        <strong>{title}</strong>
        {detail ? <span>{detail}</span> : null}
      </span>
      {trailing ?? (href ? <AppIcon className="list-row__chevron" name="chevron" /> : null)}
    </>
  );

  return href ? (
    <Link className="list-row" href={href}>
      {content}
    </Link>
  ) : (
    <div className="list-row">{content}</div>
  );
}

type SectionHeadingProperties = Readonly<{
  action?: ReactNode;
  subtitle?: string;
  title: string;
}>;

export function SectionHeading({ action, subtitle, title }: SectionHeadingProperties) {
  return (
    <header className="section-heading">
      <div>
        <h2>{title}</h2>
        {subtitle ? <p>{subtitle}</p> : null}
      </div>
      {action}
    </header>
  );
}

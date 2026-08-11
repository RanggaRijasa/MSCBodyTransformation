import type { ReactNode } from "react";

import { AppButton } from "@/shared/ui/controls/actions";
import { AppIcon, type AppIconName } from "@/shared/ui/icons/app-icon";

export type StatusTone = "success" | "warning" | "error" | "info" | "neutral";

const statusIcons: Record<StatusTone, AppIconName> = {
  success: "check",
  warning: "warning",
  error: "error",
  info: "info",
  neutral: "info",
};

export function StatusBadge({
  children,
  tone = "neutral",
}: Readonly<{ children: ReactNode; tone?: StatusTone }>) {
  return (
    <span className={`status-badge status-badge--${tone}`}>
      <AppIcon name={statusIcons[tone]} />
      <span>{children}</span>
    </span>
  );
}

type MetricProperties = Readonly<{
  label: string;
  value: string;
}>;

export function Metric({ label, value }: MetricProperties) {
  return (
    <div className="metric">
      <span>{label}</span>
      <strong className="monospaced-numeric">{value}</strong>
    </div>
  );
}

type ProgressProperties = Readonly<{
  label: string;
  value: number;
}>;

export function Progress({ label, value }: ProgressProperties) {
  const boundedValue = Math.min(Math.max(value, 0), 100);
  return (
    <div className="app-progress">
      <div className="app-progress__label">
        <span>{label}</span>
        <span className="monospaced-numeric">{boundedValue}%</span>
      </div>
      <progress aria-label={label} max={100} value={boundedValue} />
    </div>
  );
}

type StateMessageProperties = Readonly<{
  actionLabel?: string;
  description: string;
  onAction?: () => void;
  title: string;
  tone?: "empty" | "error";
}>;

export function StateMessage({
  actionLabel,
  description,
  onAction,
  title,
  tone = "empty",
}: StateMessageProperties) {
  return (
    <section
      className={`state-message state-message--${tone}`}
      role={tone === "error" ? "alert" : "status"}
    >
      <AppIcon name={tone === "error" ? "error" : "info"} />
      <div>
        <h2>{title}</h2>
        <p>{description}</p>
        {actionLabel && onAction ? <AppButton onClick={onAction}>{actionLabel}</AppButton> : null}
      </div>
    </section>
  );
}

export function Skeleton({ label = "Memuat konten" }: Readonly<{ label?: string }>) {
  return (
    <div aria-label={label} className="skeleton-stack" role="status">
      <span className="skeleton skeleton--title" />
      <span className="skeleton" />
      <span className="skeleton" />
    </div>
  );
}

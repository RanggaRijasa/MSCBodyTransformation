import type { FormHTMLAttributes, ReactNode } from "react";

import { AppButton } from "@/shared/ui/controls/actions";
import { AppIcon } from "@/shared/ui/icons/app-icon";

type FilterSummaryProperties = Readonly<{
  onClick: () => void;
  summary: string;
  title: string;
}>;

export function FilterSummary({ onClick, summary, title }: FilterSummaryProperties) {
  return (
    <button className="filter-summary" onClick={onClick} type="button">
      <AppIcon name="filter" />
      <span>
        <strong>{title}</strong>
        <span>{summary}</span>
      </span>
      <AppIcon name="chevron" />
    </button>
  );
}

export function FilterActions({
  onApply,
  onReset,
}: Readonly<{ onApply: () => void; onReset: () => void }>) {
  return (
    <footer className="filter-actions">
      <AppButton onClick={onReset} variant="secondary">
        Atur ulang
      </AppButton>
      <AppButton onClick={onApply}>Terapkan filter</AppButton>
    </footer>
  );
}

export function FilterForm({
  children,
  className = "",
  ...properties
}: Readonly<FormHTMLAttributes<HTMLFormElement> & { children: ReactNode }>) {
  return (
    <form {...properties} className={`filter-form ${className}`.trim()}>
      {children}
    </form>
  );
}

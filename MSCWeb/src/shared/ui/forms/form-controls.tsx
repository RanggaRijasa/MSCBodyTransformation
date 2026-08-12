import type {
  InputHTMLAttributes,
  ReactNode,
  SelectHTMLAttributes,
  TextareaHTMLAttributes,
} from "react";

import { Input } from "@/shared/ui/primitives/input";
import { Label } from "@/shared/ui/primitives/label";
import { Textarea } from "@/shared/ui/primitives/textarea";

type FieldShellProperties = Readonly<{
  children: ReactNode;
  description?: string | undefined;
  error?: string | undefined;
  htmlFor: string;
  label: string;
}>;

export function FieldShell({ children, description, error, htmlFor, label }: FieldShellProperties) {
  const descriptionId = description ? `${htmlFor}-description` : undefined;
  const errorId = error ? `${htmlFor}-error` : undefined;
  return (
    <div className="form-field">
      <Label htmlFor={htmlFor}>{label}</Label>
      <div>{children}</div>
      {description ? (
        <p className="form-field__description" id={descriptionId}>
          {description}
        </p>
      ) : null}
      {error ? (
        <p className="form-field__error" id={errorId} role="alert">
          {error}
        </p>
      ) : null}
    </div>
  );
}

type TextFieldProperties = Readonly<
  InputHTMLAttributes<HTMLInputElement> & {
    description?: string;
    error?: string;
    label: string;
  }
>;

export function TextField({ description, error, id, label, ...properties }: TextFieldProperties) {
  if (!id) {
    throw new Error("TextField memerlukan id yang stabil.");
  }
  const describedBy = [
    description ? `${id}-description` : undefined,
    error ? `${id}-error` : undefined,
  ]
    .filter(Boolean)
    .join(" ");

  return (
    <FieldShell description={description} error={error} htmlFor={id} label={label}>
      <Input
        {...properties}
        aria-describedby={describedBy || undefined}
        aria-invalid={Boolean(error)}
        className="form-control"
        id={id}
      />
    </FieldShell>
  );
}

type SelectFieldProperties = Readonly<
  SelectHTMLAttributes<HTMLSelectElement> & {
    description?: string;
    error?: string;
    label: string;
  }
>;

export function SelectField({
  children,
  description,
  error,
  id,
  label,
  ...properties
}: SelectFieldProperties) {
  if (!id) {
    throw new Error("SelectField memerlukan id yang stabil.");
  }
  const describedBy = [
    description ? `${id}-description` : undefined,
    error ? `${id}-error` : undefined,
  ]
    .filter(Boolean)
    .join(" ");
  return (
    <FieldShell description={description} error={error} htmlFor={id} label={label}>
      <select
        {...properties}
        aria-describedby={describedBy || undefined}
        aria-invalid={Boolean(error)}
        className="form-control"
        id={id}
      >
        {children}
      </select>
    </FieldShell>
  );
}

type TextareaFieldProperties = Readonly<
  TextareaHTMLAttributes<HTMLTextAreaElement> & {
    description?: string;
    error?: string;
    label: string;
  }
>;

export function TextareaField({
  description,
  error,
  id,
  label,
  ...properties
}: TextareaFieldProperties) {
  if (!id) {
    throw new Error("TextareaField memerlukan id yang stabil.");
  }
  const describedBy = [
    description ? `${id}-description` : undefined,
    error ? `${id}-error` : undefined,
  ]
    .filter(Boolean)
    .join(" ");
  return (
    <FieldShell description={description} error={error} htmlFor={id} label={label}>
      <Textarea
        {...properties}
        aria-describedby={describedBy || undefined}
        aria-invalid={Boolean(error)}
        className="form-control"
        id={id}
      />
    </FieldShell>
  );
}

type ChoiceFieldProperties = Readonly<
  Omit<InputHTMLAttributes<HTMLInputElement>, "type"> & {
    description?: string;
    label: string;
    type: "checkbox" | "radio";
  }
>;

export function ChoiceField({
  description,
  id,
  label,
  type,
  ...properties
}: ChoiceFieldProperties) {
  if (!id) {
    throw new Error("ChoiceField memerlukan id yang stabil.");
  }
  return (
    <label className="choice-field" htmlFor={id}>
      <input {...properties} id={id} type={type} />
      <span>
        <strong>{label}</strong>
        {description ? <span>{description}</span> : null}
      </span>
    </label>
  );
}

export function FormErrorSummary({
  children,
  title,
}: Readonly<{ children: ReactNode; title: string }>) {
  return (
    <section aria-labelledby="form-error-summary-title" className="form-error-summary" role="alert">
      <h2 id="form-error-summary-title">{title}</h2>
      {children}
    </section>
  );
}

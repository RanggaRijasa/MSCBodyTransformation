"use client";

import { useEffect, useRef } from "react";

import { copy } from "@/shared/i18n/id";

export function RouteErrorBoundary({ reset }: Readonly<{ reset: () => void }>) {
  const headingReference = useRef<HTMLHeadingElement>(null);

  useEffect(() => headingReference.current?.focus(), []);

  return (
    <main className="route-error" id="main-content">
      <section aria-labelledby="route-error-title" role="alert">
        <h1 id="route-error-title" ref={headingReference} tabIndex={-1}>
          {copy.error.title}
        </h1>
        <p>{copy.error.message}</p>
        <button className="button button--primary" onClick={reset} type="button">
          {copy.common.tryAgain}
        </button>
      </section>
    </main>
  );
}

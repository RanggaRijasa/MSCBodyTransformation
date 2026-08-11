"use client";

import { useEffect } from "react";

import { copy } from "@/shared/i18n/id";

type ErrorPageProperties = Readonly<{
  error: Error & { digest?: string };
  reset: () => void;
}>;

export default function ErrorPage({ error, reset }: ErrorPageProperties) {
  useEffect(() => {
    const safeErrorName = error.name || "UnknownError";
    console.error("app_render_failed", { name: safeErrorName });
  }, [error]);

  return (
    <main className="state-page">
      <h1>{copy.error.title}</h1>
      <p>{copy.error.message}</p>
      <button className="primary-button" type="button" onClick={reset}>
        {copy.common.tryAgain}
      </button>
    </main>
  );
}

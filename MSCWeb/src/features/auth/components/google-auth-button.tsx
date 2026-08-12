"use client";

import { useId, useState, type MouseEvent } from "react";

type GoogleAuthButtonProperties = Readonly<{
  mode: "login" | "register" | "reauthenticate";
  returnTo?: string | undefined;
}>;

export function GoogleAuthButton({ mode, returnTo }: GoogleAuthButtonProperties) {
  const [state, setState] = useState<"idle" | "offline" | "pending">("idle");
  const statusId = useId();
  const parameters = new URLSearchParams({ mode });
  if (returnTo) parameters.set("returnTo", returnTo);
  const defaultLabel = mode === "register" ? "Daftar dengan Google" : "Lanjutkan dengan Google";
  const label = state === "pending" ? "Membuka Google…" : defaultLabel;

  function begin(event: MouseEvent<HTMLAnchorElement>) {
    if (!navigator.onLine) {
      event.preventDefault();
      setState("offline");
      return;
    }
    setState("pending");
  }

  return (
    <div className="google-auth-action">
      <a
        aria-busy={state === "pending" || undefined}
        aria-describedby={state === "offline" ? statusId : undefined}
        className="google-auth-button"
        href={`/auth/google/start?${parameters.toString()}`}
        onClick={begin}
      >
        {state === "pending" ? (
          <span aria-hidden="true" className="google-auth-button__spinner" />
        ) : (
          <span aria-hidden="true" className="google-auth-button__brand" />
        )}
        <span>{label}</span>
      </a>
      {state === "offline" ? (
        <p className="google-auth-action__status" id={statusId} role="alert">
          Tidak ada koneksi. Sambungkan perangkat, lalu coba lagi.
        </p>
      ) : null}
    </div>
  );
}

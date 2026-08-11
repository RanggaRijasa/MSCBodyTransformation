"use client";

import { useState } from "react";

import { AppButton } from "@/shared/ui/controls/actions";

type ShareState = "idle" | "loading" | "shared" | "downloaded" | "error";

export function SafeImageShareButton({
  fileName,
  label = "Bagikan QR",
  sourceUrl,
}: Readonly<{ fileName: string; label?: string; sourceUrl: string }>) {
  const [state, setState] = useState<ShareState>("idle");

  async function share() {
    setState("loading");
    try {
      const response = await fetch(sourceUrl, { cache: "no-store", credentials: "same-origin" });
      if (!response.ok) throw new Error("image_unavailable");
      const blob = await response.blob();
      const file = new File([blob], fileName, { type: blob.type });
      if (navigator.share && navigator.canShare?.({ files: [file] })) {
        await navigator.share({ files: [file], title: "QR Coach MSC" });
        setState("shared");
        return;
      }
      const objectUrl = URL.createObjectURL(blob);
      const anchor = document.createElement("a");
      anchor.download = fileName;
      anchor.href = objectUrl;
      anchor.click();
      queueMicrotask(() => URL.revokeObjectURL(objectUrl));
      setState("downloaded");
    } catch (error) {
      if (error instanceof DOMException && error.name === "AbortError") {
        setState("idle");
      } else {
        setState("error");
      }
    }
  }

  return (
    <div className="safe-share">
      <AppButton isLoading={state === "loading"} onClick={() => void share()} variant="secondary">
        {label}
      </AppButton>
      <p aria-live="polite">
        {state === "shared" ? "QR dibagikan." : null}
        {state === "downloaded" ? "Gambar QR diunduh karena fitur Bagikan tidak tersedia." : null}
        {state === "error" ? "QR belum dapat dibagikan. Coba lagi." : null}
      </p>
    </div>
  );
}

"use client";

import { useEffect, useState } from "react";

import { AppButton, StatusBadge, Surface } from "@/shared/ui";

type PushState =
  "active" | "configuration-missing" | "denied" | "disabled" | "enabling" | "error" | "unsupported";

function decodeApplicationServerKey(value: string): Uint8Array<ArrayBuffer> {
  const padding = "=".repeat((4 - (value.length % 4)) % 4);
  const base64 = (value + padding).replaceAll("-", "+").replaceAll("_", "/");
  const binary = window.atob(base64);
  const bytes = new Uint8Array(new ArrayBuffer(binary.length));
  for (let index = 0; index < binary.length; index += 1) bytes[index] = binary.charCodeAt(index);
  return bytes;
}

function userAgentFamily() {
  const value = navigator.userAgent.toLowerCase();
  const isIOS = /iphone|ipad|ipod/.test(value);
  if (isIOS && /safari/.test(value)) return "ios_safari";
  if (/android/.test(value) && /chrome/.test(value)) return "android_chrome";
  if (/chrome|chromium|edg/.test(value)) return "desktop_chromium";
  if (/safari/.test(value)) return "desktop_safari";
  return "other";
}

function isStandalone() {
  return window.matchMedia("(display-mode: standalone)").matches;
}

async function persistSubscription(subscription: PushSubscription) {
  const json = subscription.toJSON();
  const response = await fetch("/api/push/subscriptions", {
    body: JSON.stringify({
      authSecret: json.keys?.auth,
      endpoint: subscription.endpoint,
      p256dh: json.keys?.p256dh,
      userAgentFamily: userAgentFamily(),
    }),
    cache: "no-store",
    headers: { "Content-Type": "application/json" },
    method: "POST",
  });
  if (!response.ok) throw new Error("push_subscription_save_failed");
}

export function PushNotificationSettings() {
  const publicKey = process.env.NEXT_PUBLIC_WEB_PUSH_VAPID_PUBLIC_KEY?.trim() ?? "";
  const [state, setState] = useState<PushState>("disabled");
  const [message, setMessage] = useState("Notifikasi hanya diaktifkan setelah kamu memilihnya.");
  const [iosRequiresStandalone, setIosRequiresStandalone] = useState(false);

  useEffect(() => {
    let isActive = true;
    const initialize = async () => {
      await Promise.resolve();
      if (
        !("serviceWorker" in navigator) ||
        !("PushManager" in window) ||
        !("Notification" in window)
      ) {
        if (isActive) setState("unsupported");
        return;
      }
      if (isActive)
        setIosRequiresStandalone(/iphone|ipad|ipod/i.test(navigator.userAgent) && !isStandalone());
      if (!publicKey) {
        if (isActive) setState("configuration-missing");
        return;
      }
      if (Notification.permission === "denied") {
        if (isActive) setState("denied");
        return;
      }
      const registration = await navigator.serviceWorker.ready;
      const subscription = await registration.pushManager.getSubscription();
      if (isActive) setState(subscription ? "active" : "disabled");
    };
    void initialize();
    const handleServiceWorkerMessage = (event: MessageEvent) => {
      if (event.data?.type === "MSC_PUSH_SUBSCRIPTION_CHANGED") setState("disabled");
    };
    navigator.serviceWorker?.addEventListener("message", handleServiceWorkerMessage);
    return () => {
      isActive = false;
      navigator.serviceWorker?.removeEventListener("message", handleServiceWorkerMessage);
    };
  }, [publicKey]);

  async function enable() {
    setState("enabling");
    setMessage("Menyiapkan notifikasi…");
    try {
      const permission = await Notification.requestPermission();
      if (permission !== "granted") {
        setState(permission === "denied" ? "denied" : "disabled");
        setMessage("Notifikasi belum diaktifkan. Kamu dapat mencobanya lagi dari pengaturan ini.");
        return;
      }
      const registration = await navigator.serviceWorker.ready;
      const existing = await registration.pushManager.getSubscription();
      const subscription =
        existing ??
        (await registration.pushManager.subscribe({
          applicationServerKey: decodeApplicationServerKey(publicKey),
          userVisibleOnly: true,
        }));
      await persistSubscription(subscription);
      setState("active");
      setMessage("Notifikasi aktif untuk pemeriksaan aktivitas, pembayaran, dan pengajuan Coach.");
    } catch {
      setState(navigator.onLine ? "error" : "disabled");
      setMessage(
        navigator.onLine
          ? "Notifikasi belum dapat diaktifkan. Coba lagi beberapa saat lagi."
          : "Kamu sedang offline. Sambungkan perangkat lalu coba lagi.",
      );
    }
  }

  async function disable() {
    setMessage("Menonaktifkan notifikasi…");
    try {
      const registration = await navigator.serviceWorker.ready;
      const subscription = await registration.pushManager.getSubscription();
      if (subscription) {
        await fetch("/api/push/subscriptions", {
          body: JSON.stringify({ endpoint: subscription.endpoint }),
          cache: "no-store",
          headers: { "Content-Type": "application/json" },
          method: "DELETE",
        });
        await subscription.unsubscribe();
      }
      setState("disabled");
      setMessage("Notifikasi dinonaktifkan pada perangkat ini.");
    } catch {
      setState("error");
      setMessage("Notifikasi belum dapat dinonaktifkan. Periksa koneksi lalu coba lagi.");
    }
  }

  const statusLabel =
    state === "active"
      ? "Aktif"
      : state === "denied"
        ? "Diblokir browser"
        : state === "unsupported"
          ? "Tidak didukung"
          : "Nonaktif";

  return (
    <Surface className="push-settings">
      <div className="push-settings__heading">
        <div>
          <h2>Notifikasi</h2>
          <p>Dapatkan pembaruan penting tanpa memasukkan isi data privat ke notifikasi.</p>
        </div>
        <StatusBadge tone={state === "active" ? "success" : "neutral"}>{statusLabel}</StatusBadge>
      </div>
      {state === "denied" ? (
        <p>
          Izinkan notifikasi melalui pengaturan situs di browser, lalu buka halaman ini kembali.
        </p>
      ) : null}
      {state === "configuration-missing" ? (
        <p>Notifikasi belum dikonfigurasi pada lingkungan ini.</p>
      ) : null}
      {state === "unsupported" ? (
        <p>
          Browser ini belum mendukung Web Push. Di iPhone, pasang MSC ke Layar Utama lebih dulu.
        </p>
      ) : null}
      {iosRequiresStandalone ? (
        <p>Di iPhone, buka MSC dari ikon Layar Utama sebelum mengaktifkan notifikasi.</p>
      ) : null}
      <p aria-live="polite">{message}</p>
      {state === "active" ? (
        <AppButton onClick={() => void disable()} variant="secondary">
          Nonaktifkan notifikasi
        </AppButton>
      ) : null}
      {["disabled", "error"].includes(state) && !iosRequiresStandalone ? (
        <AppButton disabled={state === "enabling"} onClick={() => void enable()}>
          Aktifkan notifikasi
        </AppButton>
      ) : null}
    </Surface>
  );
}

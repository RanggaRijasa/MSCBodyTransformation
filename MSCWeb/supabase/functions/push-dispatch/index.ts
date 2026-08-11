import { createClient } from "npm:@supabase/supabase-js@2.112.2";
import webpush from "npm:web-push@3.6.7";

type OutboxRow = Readonly<{
  attempts: number;
  destination_path: string;
  event_type: NotificationType;
  id: string;
  recipient_user_id: string;
  status: "failed" | "pending" | "processing" | "sent";
}>;

type SubscriptionRow = Readonly<{
  auth_secret: string;
  endpoint: string;
  id: string;
  p256dh: string;
}>;

type NotificationType = keyof typeof notificationCopy;

const notificationCopy = {
  coach_application_approved: {
    body: "Pengajuan Coach-mu sudah disetujui.",
    title: "Akses Coach aktif",
  },
  coach_application_rejected: {
    body: "Pengajuan Coach telah diperiksa. Buka MSC untuk melihat hasilnya.",
    title: "Pembaruan pengajuan Coach",
  },
  coach_application_review_pending: {
    body: "Ada pengajuan Coach yang menunggu pemeriksaan.",
    title: "Pengajuan Coach baru",
  },
  coach_review_pending: {
    body: "Ada aktivitas Peserta yang menunggu pemeriksaan.",
    title: "Pemeriksaan baru",
  },
  payment_approved: {
    body: "Pembayaran sudah disetujui. Buka MSC untuk melanjutkan.",
    title: "Pembayaran disetujui",
  },
  payment_correction_required: {
    body: "Bukti pembayaran perlu diperbaiki. Buka MSC untuk melihat petunjuk.",
    title: "Perbaikan pembayaran",
  },
  payment_rejected: {
    body: "Pembayaran telah diperiksa. Buka MSC untuk melihat hasilnya.",
    title: "Pembaruan pembayaran",
  },
  payment_review_pending: {
    body: "Ada pembayaran yang menunggu pemeriksaan.",
    title: "Pembayaran baru",
  },
  submission_approved: {
    body: "Aktivitasmu sudah disetujui oleh Coach.",
    title: "Aktivitas disetujui",
  },
  submission_rejected: {
    body: "Aktivitas perlu diperbaiki. Buka MSC untuk melihat catatan Coach.",
    title: "Perbaikan aktivitas",
  },
} as const;

function timingSafeEqual(left: string, right: string) {
  const encoder = new TextEncoder();
  const leftBytes = encoder.encode(left);
  const rightBytes = encoder.encode(right);
  if (leftBytes.length !== rightBytes.length) return false;
  let difference = 0;
  for (let index = 0; index < leftBytes.length; index += 1)
    difference |= leftBytes[index]! ^ rightBytes[index]!;
  return difference === 0;
}

function retryAt(attempts: number) {
  const seconds = Math.min(3_600, 30 * 2 ** Math.max(0, attempts - 1));
  return new Date(Date.now() + seconds * 1000).toISOString();
}

Deno.serve(async (request) => {
  if (request.method !== "POST") return new Response(null, { status: 405 });
  const projectUrl = Deno.env.get("SUPABASE_URL") ?? "";
  const secretKey = Deno.env.get("SUPABASE_SECRET_KEY") ?? "";
  const dispatchSecret = Deno.env.get("PUSH_DISPATCH_SECRET") ?? "";
  const vapidPublicKey = Deno.env.get("WEB_PUSH_VAPID_PUBLIC_KEY") ?? "";
  const vapidPrivateKey = Deno.env.get("WEB_PUSH_VAPID_PRIVATE_KEY") ?? "";
  const vapidSubject = Deno.env.get("WEB_PUSH_VAPID_SUBJECT") ?? "";
  const suppliedSecret = request.headers.get("x-internal-secret") ?? "";
  if (!projectUrl || !secretKey || !dispatchSecret || !vapidPublicKey || !vapidPrivateKey) {
    return Response.json({ code: "push_configuration_missing" }, { status: 503 });
  }
  if (!timingSafeEqual(suppliedSecret, dispatchSecret)) {
    return Response.json({ code: "authentication_required" }, { status: 401 });
  }

  webpush.setVapidDetails(
    vapidSubject || "mailto:operator@example.invalid",
    vapidPublicKey,
    vapidPrivateKey,
  );
  const supabase = createClient(projectUrl, secretKey, {
    auth: { persistSession: false },
  });
  const { data, error } = await supabase
    .from("web_push_outbox")
    .select("id,recipient_user_id,event_type,destination_path,status,attempts")
    .in("status", ["pending", "failed"])
    .lte("next_attempt_at", new Date().toISOString())
    .lt("attempts", 8)
    .order("created_at", { ascending: true })
    .limit(50);
  if (error) return Response.json({ code: "push_outbox_unavailable" }, { status: 503 });

  let failed = 0;
  let sent = 0;
  for (const candidate of (data ?? []) as OutboxRow[]) {
    const attempts = candidate.attempts + 1;
    const claim = await supabase
      .from("web_push_outbox")
      .update({ attempts, status: "processing" })
      .eq("id", candidate.id)
      .eq("status", candidate.status)
      .select("id")
      .maybeSingle();
    if (claim.error || !claim.data) continue;

    const subscriptions = await supabase
      .from("web_push_subscriptions")
      .select("id,endpoint,p256dh,auth_secret")
      .eq("user_id", candidate.recipient_user_id)
      .is("revoked_at", null);
    if (subscriptions.error) {
      failed += 1;
      await supabase
        .from("web_push_outbox")
        .update({
          last_error_code: "subscription_lookup_failed",
          next_attempt_at: retryAt(attempts),
          status: "failed",
        })
        .eq("id", candidate.id);
      continue;
    }

    const copy = notificationCopy[candidate.event_type];
    const payload = JSON.stringify({
      ...copy,
      tag: `${candidate.event_type}:${candidate.id}`,
      url: candidate.destination_path,
    });
    let delivered = 0;
    for (const subscription of (subscriptions.data ?? []) as SubscriptionRow[]) {
      try {
        await webpush.sendNotification(
          {
            endpoint: subscription.endpoint,
            keys: { auth: subscription.auth_secret, p256dh: subscription.p256dh },
          },
          payload,
          { TTL: 3_600, urgency: "normal" },
        );
        delivered += 1;
      } catch (caught) {
        const statusCode =
          typeof caught === "object" && caught !== null && "statusCode" in caught
            ? Number(caught.statusCode)
            : 0;
        if (statusCode === 404 || statusCode === 410) {
          await supabase
            .from("web_push_subscriptions")
            .update({ revoked_at: new Date().toISOString() })
            .eq("id", subscription.id);
        }
      }
    }

    if (delivered > 0 || (subscriptions.data ?? []).length === 0) {
      sent += 1;
      await supabase
        .from("web_push_outbox")
        .update({ last_error_code: null, processed_at: new Date().toISOString(), status: "sent" })
        .eq("id", candidate.id);
    } else {
      failed += 1;
      await supabase
        .from("web_push_outbox")
        .update({
          last_error_code: "delivery_failed",
          next_attempt_at: retryAt(attempts),
          status: "failed",
        })
        .eq("id", candidate.id);
    }
  }

  return Response.json({ failed, processed: (data ?? []).length, sent });
});

"use client";

import { useRouter } from "next/navigation";
import { useState } from "react";

import type { OpaqueCoachQrPayload } from "@/domain/media/qr-payload";
import { memberLevelLabels, type AuthenticatedProfile } from "@/features/auth/model/auth-model";
import { ImageAcquisition, QrScannerDialog } from "@/features/device-media";
import type { ProcessedBrowserImage } from "@/infrastructure/browser-media/browser-image-processor";
import { AppButton } from "@/shared/ui/controls/actions";
import { TextField } from "@/shared/ui/forms/form-controls";
import { Avatar, StatusBadge, Surface } from "@/shared/ui";

const deletionMessages: Readonly<Record<string, string>> = {
  account_relationships_require_transfer:
    "Akun belum dapat dihapus karena assignment aktif harus dipindahkan oleh Admin.",
  admin_account_deletion_not_allowed: "Akun Admin tidak dapat dihapus melalui aplikasi.",
  private_media_cleanup_required:
    "Media pribadi belum selesai dibersihkan. Coba lagi setelah beberapa saat.",
  recent_reauthentication_required:
    "Masuk ulang dengan Google terlebih dahulu, lalu ulangi penghapusan akun.",
};

type ParticipantProfileContext = Readonly<{
  avatarUrl: string | null;
  coach: Readonly<{ city: string | null; displayName: string; photoUrl: string | null }> | null;
}>;

export function ProfileLifecycle({
  participantContext,
  profile,
}: Readonly<{
  participantContext: ParticipantProfileContext | null;
  profile: AuthenticatedProfile;
}>) {
  const router = useRouter();
  const [displayName, setDisplayName] = useState(profile.displayName);
  const [phoneNumber, setPhoneNumber] = useState(profile.phoneNumber ?? "");
  const [isBusy, setIsBusy] = useState(false);
  const [message, setMessage] = useState<string | null>(null);
  const [avatarUrl, setAvatarUrl] = useState(participantContext?.avatarUrl ?? profile.avatarUrl);
  const [pendingAvatar, setPendingAvatar] = useState<ProcessedBrowserImage | null>(null);
  const [coach, setCoach] = useState(participantContext?.coach ?? null);
  const [isScannerOpen, setScannerOpen] = useState(false);
  const [pendingCoachQr, setPendingCoachQr] = useState<OpaqueCoachQrPayload | null>(null);

  async function saveProfile() {
    setIsBusy(true);
    setMessage(null);
    try {
      const response = await fetch("/api/profile", {
        body: JSON.stringify({ displayName, phoneNumber }),
        headers: { "Content-Type": "application/json" },
        method: "PATCH",
      });
      if (!response.ok) throw new Error("profile_update_failed");
      setMessage("Profil berhasil diperbarui.");
      router.refresh();
    } catch {
      setMessage("Profil belum dapat diperbarui. Periksa data dan koneksi, lalu coba lagi.");
    } finally {
      setIsBusy(false);
    }
  }

  async function deleteAccount() {
    if (
      !window.confirm(
        "Hapus akun dan data pribadi yang dapat dihapus? Tindakan ini tidak dapat dibatalkan.",
      )
    )
      return;
    setIsBusy(true);
    setMessage(null);
    try {
      const response = await fetch("/api/account/delete", { method: "POST" });
      if (!response.ok) {
        const payload = (await response.json()) as { code?: string };
        setMessage(
          deletionMessages[payload.code ?? ""] ??
            "Akun belum dapat dihapus. Coba lagi setelah masuk ulang.",
        );
        return;
      }
      router.replace("/masuk?status=akun-dihapus");
      router.refresh();
    } catch {
      setMessage("Tidak ada koneksi. Akun belum dihapus dan aman untuk dicoba lagi.");
    } finally {
      setIsBusy(false);
    }
  }

  async function uploadAvatar() {
    if (!pendingAvatar) return;
    setIsBusy(true);
    setMessage(null);
    const form = new FormData();
    form.set("image", new File([pendingAvatar.fullImage], "avatar.jpg", { type: "image/jpeg" }));
    form.set("idempotencyKey", crypto.randomUUID());
    try {
      const response = await fetch("/api/profile/avatar", { body: form, method: "POST" });
      if (!response.ok) throw new Error("avatar_failed");
      const payload = (await response.json()) as { avatarUrl?: unknown };
      if (typeof payload.avatarUrl !== "string") throw new Error("avatar_invalid");
      setAvatarUrl(payload.avatarUrl);
      setPendingAvatar(null);
      setMessage("Foto profil berhasil diperbarui.");
      router.refresh();
    } catch {
      setMessage("Foto profil belum dapat diperbarui. Periksa koneksi lalu coba lagi.");
    } finally {
      setIsBusy(false);
    }
  }

  async function changeCoach() {
    if (!pendingCoachQr) return;
    setIsBusy(true);
    setMessage(null);
    const storageKey = "msc.profile.coach-change-key";
    let idempotencyKey = window.localStorage.getItem(storageKey);
    if (!idempotencyKey) {
      idempotencyKey = crypto.randomUUID();
      window.localStorage.setItem(storageKey, idempotencyKey);
    }
    try {
      const response = await fetch("/api/profile/coach", {
        body: JSON.stringify({ coachQrPayload: pendingCoachQr, idempotencyKey }),
        headers: { "Content-Type": "application/json" },
        method: "POST",
      });
      if (!response.ok) throw new Error("coach_change_failed");
      const payload = (await response.json()) as { displayName?: unknown };
      if (typeof payload.displayName !== "string") throw new Error("coach_change_invalid");
      window.localStorage.removeItem(storageKey);
      setCoach({ city: null, displayName: payload.displayName, photoUrl: null });
      setPendingCoachQr(null);
      setMessage("Coach berhasil diperbarui melalui QR terverifikasi.");
      router.refresh();
    } catch {
      setMessage(
        "Coach belum dapat diperbarui. Pastikan QR valid dan Coach masih aktif, lalu coba lagi.",
      );
    } finally {
      setIsBusy(false);
    }
  }

  return (
    <div className="profile-lifecycle">
      <section
        className="app-surface profile-lifecycle__section"
        aria-labelledby="profile-avatar-title"
      >
        <h2 id="profile-avatar-title">Foto profil</h2>
        <Avatar
          {...(avatarUrl ? { imageUrl: avatarUrl } : {})}
          name={profile.displayName}
          size={88}
        />
        <ImageAcquisition label="Pilih foto profil" onProcessed={setPendingAvatar} />
        <AppButton disabled={isBusy || !pendingAvatar} onClick={() => void uploadAvatar()}>
          Simpan foto profil
        </AppButton>
      </section>
      <section
        className="app-surface profile-lifecycle__section"
        aria-labelledby="profile-fields-title"
      >
        <h2 id="profile-fields-title">Informasi akun</h2>
        <TextField
          autoComplete="name"
          id="profile-name"
          label="Nama lengkap"
          maxLength={80}
          onChange={(event) => setDisplayName(event.target.value)}
          value={displayName}
        />
        <TextField
          autoComplete="tel"
          id="profile-phone"
          inputMode="tel"
          label="Nomor HP"
          onChange={(event) => setPhoneNumber(event.target.value)}
          value={phoneNumber}
        />
        <TextField
          disabled
          id="profile-email"
          label="Email (tidak dapat diubah di sini)"
          value={profile.email}
        />
        <dl className="profile-readonly">
          <div>
            <dt>Role</dt>
            <dd>
              {profile.role === "participant"
                ? "Peserta"
                : profile.role === "coach"
                  ? "Coach"
                  : "Admin"}
            </dd>
          </div>
          <div>
            <dt>Status</dt>
            <dd>{profile.onboardingStatus === "active" ? "Aktif" : "Dalam proses"}</dd>
          </div>
          <div>
            <dt>Level member</dt>
            <dd>{profile.memberLevel ? memberLevelLabels[profile.memberLevel] : "Belum diisi"}</dd>
          </div>
        </dl>
        <AppButton disabled={isBusy} onClick={() => void saveProfile()}>
          Simpan perubahan
        </AppButton>
      </section>
      {profile.role === "participant" ? (
        <section
          className="app-surface profile-lifecycle__section"
          aria-labelledby="profile-coach-title"
        >
          <h2 id="profile-coach-title">Coach pendamping</h2>
          {coach ? (
            <Surface className="profile-coach-card">
              <Avatar
                {...(coach.photoUrl ? { imageUrl: coach.photoUrl } : {})}
                name={coach.displayName}
              />
              <div>
                <h3>{coach.displayName}</h3>
                <p>{coach.city || "Lokasi belum dicantumkan"}</p>
              </div>
              <StatusBadge tone="success">Coach-mu</StatusBadge>
            </Surface>
          ) : (
            <p>Belum ada Coach pendamping.</p>
          )}
          <p>
            Pergantian hanya dapat dilakukan dengan memindai QR Coach aktif. Kode mentah tidak
            pernah ditampilkan atau dapat diketik.
          </p>
          <AppButton disabled={isBusy} onClick={() => setScannerOpen(true)} variant="secondary">
            Ganti Coach melalui QR
          </AppButton>
          {pendingCoachQr ? (
            <div className="profile-coach-confirm">
              <p>
                QR Coach valid terdeteksi. Konfirmasi untuk memperbarui Coach pada program aktif.
              </p>
              <AppButton disabled={isBusy} onClick={() => void changeCoach()}>
                Konfirmasi pergantian Coach
              </AppButton>
              <AppButton onClick={() => setPendingCoachQr(null)} variant="secondary">
                Batal
              </AppButton>
            </div>
          ) : null}
          <QrScannerDialog
            isOpen={isScannerOpen}
            onClose={() => setScannerOpen(false)}
            onScan={setPendingCoachQr}
          />
        </section>
      ) : null}
      <section className="app-surface profile-lifecycle__section" aria-labelledby="legal-title">
        <h2 id="legal-title">Privasi dan ketentuan</h2>
        <div className="onboarding-actions">
          <a href="/privasi">Privasi</a>
          <a href="/ketentuan">Ketentuan</a>
          <a href="/bantuan">Bantuan</a>
        </div>
      </section>
      <section className="app-surface profile-lifecycle__section" aria-labelledby="session-title">
        <h2 id="session-title">Sesi dan akun</h2>
        <p>
          Penghapusan akun memerlukan login Google yang masih baru. Data relasional yang wajib
          dipertahankan akan dianonimkan sesuai aturan server.
        </p>
        <div className="onboarding-actions">
          <form action="/auth/logout" method="post">
            <AppButton disabled={isBusy} type="submit" variant="secondary">
              Keluar
            </AppButton>
          </form>
          <a
            className="app-action app-action--secondary"
            href="/auth/google/start?mode=reauthenticate&returnTo=%2Fprofil"
          >
            Masuk ulang untuk verifikasi
          </a>
          <AppButton disabled={isBusy} onClick={() => void deleteAccount()} variant="destructive">
            Hapus akun
          </AppButton>
        </div>
      </section>
      {message ? (
        <p className="onboarding-status" role="status">
          {message}
        </p>
      ) : null}
    </div>
  );
}

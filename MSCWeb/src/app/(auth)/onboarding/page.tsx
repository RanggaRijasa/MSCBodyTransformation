import { OnboardingForm } from "@/features/auth/components/onboarding-form";
import { requireVerifiedProfile } from "@/features/auth/server/session-routing";

export default async function OnboardingPage() {
  const profile = await requireVerifiedProfile("/onboarding");
  return (
    <main className="auth-page" id="konten-utama">
      <section aria-labelledby="onboarding-title" className="auth-card onboarding-page">
        <div className="auth-card__heading">
          <p className="auth-eyebrow">Langkah terakhir</p>
          <h1 id="onboarding-title">Lengkapi profil</h1>
          <p>
            Data ini disimpan hanya setelah operasi server berhasil. Role akun tetap Peserta selama
            proses pengajuan Coach.
          </p>
        </div>
        <OnboardingForm
          initialName={profile.displayName === "Peserta baru" ? "" : profile.displayName}
        />
      </section>
    </main>
  );
}

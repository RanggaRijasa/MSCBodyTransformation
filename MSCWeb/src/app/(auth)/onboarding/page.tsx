import { AuthCloseControl } from "@/features/auth/components/auth-close-control";
import { OnboardingForm } from "@/features/auth/components/onboarding-form";
import { requireVerifiedProfile } from "@/features/auth/server/session-routing";
import { AppIcon } from "@/shared/ui/icons/app-icon";

export default async function OnboardingPage() {
  const profile = await requireVerifiedProfile("/onboarding");
  return (
    <main className="auth-page" id="konten-utama">
      <section aria-labelledby="onboarding-title" className="auth-card onboarding-page">
        <header className="auth-card__topbar">
          <span className="auth-route-title">Profil</span>
          <AuthCloseControl />
        </header>
        <div className="auth-card__heading">
          <span aria-hidden="true" className="auth-icon">
            <AppIcon name="person" />
          </span>
          <h1 autoFocus id="onboarding-title" tabIndex={-1}>
            Lengkapi profil
          </h1>
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

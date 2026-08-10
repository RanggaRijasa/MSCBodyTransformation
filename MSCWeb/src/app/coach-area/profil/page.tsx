import type { Metadata } from "next";

import { loadCoachContextOperation } from "@/application/coach/load-coach-experience";
import { ProfileLifecycle } from "@/features/auth/profile-lifecycle";
import { requireVerifiedProfile } from "@/features/auth/server/session-routing";
import { CoachAccessState, CoachPublicProfileForm } from "@/features/coach";
import { copy } from "@/shared/i18n/id";
import { StateMessage } from "@/shared/ui";

export const dynamic = "force-dynamic";
export const metadata: Metadata = { title: copy.shell.coach.profileTitle };

export default async function CoachProfilePage() {
  const profile = await requireVerifiedProfile("/coach-area/profil");
  const context = await loadCoachContextOperation();
  if (!context.isSuccess)
    return (
      <StateMessage
        description={context.error.message}
        title="Profil Coach belum dapat dimuat"
        tone="error"
      />
    );
  return (
    <div className="coach-profile">
      <header>
        <p className="coach-eyebrow">Akun Coach</p>
        <h1>Profil</h1>
        <p>Kelola identitas publik, akses, privasi, dan akun.</p>
      </header>
      {context.value.accessState === "active" ? (
        <>
          <ProfileLifecycle participantContext={null} profile={profile} />
          <CoachPublicProfileForm context={context.value} />
        </>
      ) : (
        <CoachAccessState context={context.value} />
      )}
    </div>
  );
}

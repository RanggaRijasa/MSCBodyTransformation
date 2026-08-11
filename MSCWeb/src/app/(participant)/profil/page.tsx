import type { Metadata } from "next";

import { ProfileLifecycle } from "@/features/auth/components/profile-lifecycle";
import { loadParticipantProfileContextOperation } from "@/application/participant/participant-profile-operations";
import { requireVerifiedProfile } from "@/features/auth/server/session-routing";
import { copy } from "@/shared/i18n/id";
import { PushNotificationSettings } from "@/features/push";

export const metadata: Metadata = { title: copy.shell.participant.profileTitle };

export default async function ProfilePage() {
  const profile = await requireVerifiedProfile("/profil");
  const participantContext = await loadParticipantProfileContextOperation();
  return (
    <div className="shell-page">
      <header className="shell-page__header">
        <h1>{copy.shell.participant.profileTitle}</h1>
        <p>{copy.shell.participant.profileSummary}</p>
      </header>
      <ProfileLifecycle
        participantContext={participantContext.isSuccess ? participantContext.value : null}
        profile={profile}
      />
      <PushNotificationSettings />
    </div>
  );
}

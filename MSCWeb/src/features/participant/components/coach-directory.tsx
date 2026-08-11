import type { PublicCoach } from "@/domain/participant/participant-program";
import { Avatar, StatusBadge, Surface } from "@/shared/ui";
import { ProgramNetworkStatus } from "@/features/programs";

export function CoachDirectory({ coaches }: Readonly<{ coaches: readonly PublicCoach[] }>) {
  return (
    <div className="participant-directory">
      <header>
        <h1>Coach</h1>
        <p>
          Kenali Coach approved yang tersedia. Coach-mu ditentukan melalui QR yang diverifikasi
          server.
        </p>
      </header>
      <ProgramNetworkStatus />
      {coaches.length ? (
        <div className="participant-directory__grid">
          {coaches.map((coach) => (
            <Surface className="participant-directory__card" key={coach.id}>
              <Avatar
                {...(coach.photoUrl ? { imageUrl: coach.photoUrl } : {})}
                name={coach.displayName}
                size={72}
              />
              <div>
                <h2>{coach.displayName}</h2>
                <p>{coach.city || "Lokasi belum dicantumkan"}</p>
                {coach.biography ? <p>{coach.biography}</p> : null}
              </div>
              {coach.isAssigned ? (
                <StatusBadge tone="success">Coach-mu</StatusBadge>
              ) : (
                <StatusBadge tone="neutral">Coach approved</StatusBadge>
              )}
            </Surface>
          ))}
        </div>
      ) : (
        <p>Daftar Coach approved belum tersedia.</p>
      )}
    </div>
  );
}

import Link from "next/link";

import type {
  ParticipantProgram,
  PublicCoach,
  PublicLeaderboardEntry,
  PublicWinner,
  PublicWinnerPoster,
} from "@/domain/participant/participant-program";
import type { PublicProgram } from "@/domain/programs/program";
import {
  focusedParticipantDay,
  presentParticipantStep,
} from "@/domain/services/participant-program";
import {
  formatNumber,
  formatProgramDate,
  programTimezoneLabel,
} from "@/shared/formatting/indonesian-formatters";
import { AppLink, Avatar, MediaSurface, Progress, StatusBadge, Surface } from "@/shared/ui";
import { ProgramNetworkStatus } from "@/features/programs";

type ParticipantHomeProperties = Readonly<{
  actor: "guest" | "participant";
  coaches: readonly PublicCoach[];
  displayName: string;
  programs: readonly ParticipantProgram[];
  publicPrograms: readonly PublicProgram[];
  selectedProgram: ParticipantProgram | null;
  topFive: readonly PublicLeaderboardEntry[];
  winnerPosters: readonly PublicWinnerPoster[];
  winners: readonly PublicWinner[];
}>;

function ProgramSection({
  actor,
  programs,
  publicPrograms,
  selectedProgram,
}: Pick<ParticipantHomeProperties, "actor" | "programs" | "publicPrograms" | "selectedProgram">) {
  const visiblePrograms =
    actor === "participant" ? programs.map(({ program }) => program) : publicPrograms;
  return (
    <section aria-labelledby="home-program-title">
      <div className="participant-section-heading">
        <h2 id="home-program-title">Program</h2>
        <AppLink href="/program" variant="secondary">
          Lihat semua
        </AppLink>
      </div>
      {visiblePrograms.length ? (
        <div className="participant-program-strip">
          {visiblePrograms.map((program) => (
            <Link
              aria-current={selectedProgram?.program.id === program.id ? "true" : undefined}
              className="participant-program-chip"
              href={
                actor === "participant"
                  ? `/hari-ini?program=${program.id}`
                  : `/program/${program.id}`
              }
              key={program.id}
            >
              <strong>{program.title}</strong>
              <span>
                {formatProgramDate(program.startsOn, program.timezone)} ·{" "}
                {programTimezoneLabel(program.timezone)}
              </span>
            </Link>
          ))}
        </div>
      ) : (
        <p>Belum ada program aktif. Program yang tersedia tetap dapat dilihat di katalog.</p>
      )}
    </section>
  );
}

function FocusSection({
  selectedProgram,
}: Readonly<{ selectedProgram: ParticipantProgram | null }>) {
  const focused = selectedProgram ? focusedParticipantDay(selectedProgram) : null;
  const day = focused
    ? selectedProgram?.program.days.find(({ id }) => id === focused.programDayId)
    : null;
  const firstAvailable = day?.steps.find(
    (step) => presentParticipantStep(step, focused?.accessState ?? "locked", selectedProgram!).href,
  );
  return (
    <section aria-labelledby="home-focus-title">
      <h2 id="home-focus-title">Fokus</h2>
      {selectedProgram && focused && day ? (
        <Surface className="participant-focus-card">
          <div>
            <p className="participant-eyebrow">
              {focused.isCurrentDay ? "Hari ini" : `Hari ${formatNumber.format(day.dayNumber)}`}
            </p>
            <h3>{day.title}</h3>
            <p>{day.summary || "Lanjutkan langkah program yang tersedia untukmu."}</p>
            <Progress label="Progres program" value={selectedProgram.score.progressPercentage} />
          </div>
          {firstAvailable ? (
            <AppLink href={`/program/${selectedProgram.program.id}/langkah/${firstAvailable.id}`}>
              Buka langkah berikutnya
            </AppLink>
          ) : (
            <StatusBadge tone="info">Tidak ada tindakan saat ini</StatusBadge>
          )}
        </Surface>
      ) : (
        <Surface>
          <h3>Belum ada fokus aktif</h3>
          <p>Daftar atau tunggu program dimulai untuk melihat aktivitas yang relevan.</p>
          <AppLink href="/program">Pilih program</AppLink>
        </Surface>
      )}
    </section>
  );
}

function RankingSection({ entries }: Readonly<{ entries: readonly PublicLeaderboardEntry[] }>) {
  return (
    <section aria-labelledby="home-ranking-title">
      <div className="participant-section-heading">
        <h2 id="home-ranking-title">Top 5</h2>
        <AppLink href="/peringkat" variant="secondary">
          Papan peringkat
        </AppLink>
      </div>
      {entries.length ? (
        <ol className="participant-ranking-list">
          {entries.map((entry) => (
            <li className={entry.isCurrentParticipant ? "is-current" : undefined} key={entry.id}>
              <strong>{formatNumber.format(entry.rank)}</strong>
              <span>{entry.participantDisplayName}</span>
              <span>{formatNumber.format(entry.totalPoints)} poin</span>
            </li>
          ))}
        </ol>
      ) : (
        <p>Peringkat akan tampil setelah poin server tersedia.</p>
      )}
    </section>
  );
}

function WinnerSection({
  posters,
  winners,
}: Readonly<{ posters: readonly PublicWinnerPoster[]; winners: readonly PublicWinner[] }>) {
  return (
    <section aria-labelledby="home-winner-title">
      <h2 id="home-winner-title">Pemenang</h2>
      {posters[0] ? (
        <Surface className="participant-winner-card">
          <MediaSurface
            alt={posters[0].alternativeText}
            {...(posters[0].imageUrl ? { src: posters[0].imageUrl } : {})}
          />
          <h3>{posters[0].title}</h3>
        </Surface>
      ) : winners.length ? (
        <ol className="participant-ranking-list">
          {winners.map((winner) => (
            <li key={winner.id}>
              <strong>{formatNumber.format(winner.rank)}</strong>
              <span>{winner.participantDisplayName}</span>
              <span>{formatNumber.format(winner.totalPoints)} poin</span>
            </li>
          ))}
        </ol>
      ) : (
        <p>Pemenang akan diumumkan setelah hasil program dikunci.</p>
      )}
    </section>
  );
}

function CoachSection({ coaches }: Readonly<{ coaches: readonly PublicCoach[] }>) {
  return (
    <section aria-labelledby="home-coach-title">
      <div className="participant-section-heading">
        <h2 id="home-coach-title">Coach</h2>
        <AppLink href="/coach" variant="secondary">
          Lihat Coach
        </AppLink>
      </div>
      {coaches.length ? (
        <div className="participant-coach-strip">
          {coaches.slice(0, 5).map((coach) => (
            <Surface className="participant-coach-card" key={coach.id}>
              <Avatar
                {...(coach.photoUrl ? { imageUrl: coach.photoUrl } : {})}
                name={coach.displayName}
              />
              <div>
                <h3>{coach.displayName}</h3>
                <p>{coach.city || "Lokasi belum dicantumkan"}</p>
              </div>
              {coach.isAssigned ? <StatusBadge tone="success">Coach-mu</StatusBadge> : null}
            </Surface>
          ))}
        </div>
      ) : (
        <p>Daftar Coach approved belum tersedia.</p>
      )}
    </section>
  );
}

export function ParticipantHome(properties: ParticipantHomeProperties) {
  return (
    <div className="participant-home">
      <header className="participant-home__header">
        <div>
          <p className="participant-eyebrow">MSC Body Transformation</p>
          <h1>
            {properties.actor === "participant"
              ? `Halo, ${properties.displayName}`
              : "Mulai perjalananmu"}
          </h1>
          <p>
            {properties.actor === "participant"
              ? "Fokus pada langkah yang tersedia hari ini."
              : "Masuk untuk mengikuti program, mengirim progres, dan melihat status pribadimu."}
          </p>
        </div>
        {properties.actor === "guest" ? (
          <AppLink href="/masuk?returnTo=%2Fhari-ini">Masuk atau daftar</AppLink>
        ) : null}
      </header>
      <ProgramNetworkStatus />
      <ProgramSection {...properties} />
      <FocusSection selectedProgram={properties.selectedProgram} />
      <RankingSection entries={properties.topFive} />
      <WinnerSection posters={properties.winnerPosters} winners={properties.winners} />
      <CoachSection coaches={properties.coaches} />
    </div>
  );
}

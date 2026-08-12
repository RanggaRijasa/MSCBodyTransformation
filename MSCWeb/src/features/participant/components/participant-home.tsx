import Link from "next/link";
import type { CSSProperties } from "react";

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
import { AppLink } from "@/shared/ui/controls/actions";
import { Avatar } from "@/shared/ui/identity/avatar";
import { AppIcon } from "@/shared/ui/icons/app-icon";
import { MediaSurface } from "@/shared/ui/media/media-surface";
import { StatusBadge } from "@/shared/ui/status/status";
import { Surface } from "@/shared/ui/surfaces/surfaces";
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
    <section aria-labelledby="home-program-title" className="participant-program-section">
      <div className="participant-section-heading">
        <h2 id="home-program-title">Program</h2>
        <Link className="participant-section-link" href="/program">
          Lihat semua
          <AppIcon name="chevron" variant="outline" />
        </Link>
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
              <span className="participant-program-chip__status">
                {selectedProgram?.program.id === program.id ? <AppIcon name="check" /> : null}
                {actor === "participant" ? "Diikuti" : "Tersedia"}
              </span>
              <AppIcon
                className="participant-program-chip__chevron"
                name="chevron"
                variant="outline"
              />
              <strong>{program.title}</strong>
              <span className="participant-program-chip__meta">
                {program.days.length
                  ? `${formatNumber.format(program.days.length)} hari`
                  : `${formatProgramDate(program.startsOn, program.timezone)} · ${programTimezoneLabel(program.timezone)}`}
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
  const completedStepIds = new Set([
    ...(selectedProgram?.submissions
      .filter(({ status }) => status === "approved")
      .map(({ stepId }) => stepId) ?? []),
    ...(selectedProgram?.weighedStepIds ?? []),
  ]);
  const completedStepCount = day?.steps.filter(({ id }) => completedStepIds.has(id)).length ?? 0;
  const totalStepCount = day?.steps.length ?? 0;
  const stepProgressPercentage = totalStepCount
    ? Math.round((completedStepCount / totalStepCount) * 100)
    : 0;
  return (
    <section aria-labelledby="home-focus-title">
      <h2 id="home-focus-title">Fokus hari ini</h2>
      {selectedProgram && focused && day ? (
        <Surface className="participant-focus-card">
          <div
            aria-label={`Aktivitas hari ini ${formatNumber.format(completedStepCount)} dari ${formatNumber.format(totalStepCount)} langkah selesai. Progres program ${formatNumber.format(selectedProgram.score.progressPercentage)} persen.`}
            className="participant-focus-card__progress"
            role="img"
            style={
              {
                "--participant-progress": `${stepProgressPercentage}%`,
              } as CSSProperties
            }
          >
            <strong>
              {formatNumber.format(completedStepCount)}/{formatNumber.format(totalStepCount)}
            </strong>
            <span>langkah</span>
          </div>
          <div className="participant-focus-card__copy">
            <p className="participant-eyebrow">
              {focused.isCurrentDay ? "Hari ini" : `Hari ${formatNumber.format(day.dayNumber)}`}
            </p>
            <h3>{day.title}</h3>
            <p>{day.summary || "Lanjutkan langkah program yang tersedia untukmu."}</p>
          </div>
          {firstAvailable ? (
            <AppLink href={`/program/${selectedProgram.program.id}/langkah/${firstAvailable.id}`}>
              Lanjutkan
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

function GuestFocusSection() {
  return (
    <section aria-labelledby="home-focus-title">
      <h2 id="home-focus-title">Fokus</h2>
      <Surface className="participant-focus-card">
        <div>
          <p className="participant-eyebrow">Area pribadi</p>
          <h3>Fokus pribadi terkunci</h3>
          <p>
            Pilih program publik terlebih dahulu. Setelah masuk, aktivitas dan progres hanya tampil
            untuk akunmu.
          </p>
        </div>
        <AppLink href="/program">Pilih program</AppLink>
      </Surface>
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

function CoachSection({
  coaches,
  showAssignment = true,
}: Readonly<{ coaches: readonly PublicCoach[]; showAssignment?: boolean }>) {
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
                <p className="participant-coach-card__location">
                  {coach.city || "Lokasi belum dicantumkan"}
                </p>
              </div>
              {showAssignment && coach.isAssigned ? (
                <StatusBadge tone="success">Coach-mu</StatusBadge>
              ) : null}
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
  if (properties.actor === "guest") {
    const publicRanking = properties.topFive.map((entry) => ({
      ...entry,
      isCurrentParticipant: false,
    }));
    const publicCoaches = properties.coaches.map((coach) => ({ ...coach, isAssigned: false }));

    return (
      <div className="participant-home">
        <header className="participant-home__header">
          <div>
            <p className="participant-eyebrow">MSC Body Transformation</p>
            <h1>Beranda</h1>
            <p>Jelajahi program, peringkat, pemenang, dan Coach.</p>
          </div>
        </header>
        <Surface className="participant-focus-card">
          <div>
            <p className="participant-eyebrow">Area akun</p>
            <h2>Siap memulai perjalananmu?</h2>
            <p>Masuk untuk mengikuti program dan melihat progres pribadimu.</p>
          </div>
          <AppLink href="/masuk?returnTo=%2Fhari-ini">Masuk</AppLink>
        </Surface>
        <ProgramNetworkStatus />
        <ProgramSection
          actor="guest"
          programs={[]}
          publicPrograms={properties.publicPrograms}
          selectedProgram={null}
        />
        <GuestFocusSection />
        <RankingSection entries={publicRanking} />
        <WinnerSection posters={properties.winnerPosters} winners={properties.winners} />
        <CoachSection coaches={publicCoaches} showAssignment={false} />
      </div>
    );
  }

  return (
    <div className="participant-home">
      <header className="participant-home__header">
        <h1>Beranda</h1>
      </header>
      <Link className="participant-identity-card" href="/profil">
        <Avatar name={properties.displayName} size={64} />
        <div>
          <p>Selamat datang</p>
          <h2>{properties.displayName}</h2>
        </div>
        <span className="participant-identity-card__role">MSC Peserta</span>
        <AppIcon className="participant-identity-card__chevron" name="chevron" variant="outline" />
      </Link>
      <ProgramNetworkStatus />
      <ProgramSection {...properties} />
      <FocusSection selectedProgram={properties.selectedProgram} />
      <RankingSection entries={properties.topFive} />
      <WinnerSection posters={properties.winnerPosters} winners={properties.winners} />
      <CoachSection coaches={properties.coaches} />
    </div>
  );
}

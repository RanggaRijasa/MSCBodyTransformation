import Link from "next/link";

import type {
  CoachActivityItem,
  CoachContext,
  CoachReviewItem,
  CoachRosterEntry,
} from "@/domain/coach/coach-experience";
import type { PublicLeaderboardEntry } from "@/domain/participant/participant-program";
import type { PublicProgram } from "@/domain/programs/program";
import { formatNumber } from "@/shared/formatting/indonesian-formatters";
import { Avatar } from "@/shared/ui/identity/avatar";
import { AppIcon } from "@/shared/ui/icons/app-icon";
import { Progress, StatusBadge } from "@/shared/ui/status/status";
import { Surface } from "@/shared/ui/surfaces/surfaces";
import { CoachAccessState } from "./coach-access-state";

export function CoachDashboard({
  activity,
  context,
  leaderboard,
  programs,
  reviews,
  roster,
}: Readonly<{
  activity: readonly CoachActivityItem[];
  context: CoachContext;
  leaderboard: readonly PublicLeaderboardEntry[];
  programs: readonly PublicProgram[];
  reviews: readonly CoachReviewItem[];
  roster: readonly CoachRosterEntry[];
}>) {
  if (context.accessState !== "active") return <CoachAccessState context={context} />;
  const needsAttention = roster.filter(({ attentionState }) =>
    ["falling_behind", "not_enrolled", "not_started"].includes(attentionState),
  );
  const average = roster.length
    ? Math.round(roster.reduce((sum, entry) => sum + entry.progressPercentage, 0) / roster.length)
    : 0;
  const assignedIds = new Set(roster.map(({ publicProfileId }) => publicProfileId));
  return (
    <div className="coach-dashboard">
      <header className="coach-page-header">
        <h1>Dashboard</h1>
      </header>
      <Link className="coach-identity-card" href="/coach-area/profil">
        <Avatar
          {...(context.avatarUrl ? { imageUrl: context.avatarUrl } : {})}
          name={context.displayName}
          size={64}
        />
        <div>
          <p>Selamat datang</p>
          <h2>{context.displayName}</h2>
        </div>
        <span className="coach-identity-card__role">Coach</span>
        <AppIcon className="coach-identity-card__chevron" name="chevron" variant="outline" />
      </Link>
      <section aria-labelledby="coach-quick-actions-title">
        <h2 id="coach-quick-actions-title">Aksi cepat</h2>
        <nav aria-label="Tindakan cepat Coach" className="coach-quick-actions">
          <Link href="/coach-area/pemeriksaan">
            <AppIcon name="check" />
            <strong>Periksa bukti</strong>
            <span
              aria-label={`${formatNumber.format(reviews.length)} pemeriksaan menunggu`}
              className="coach-quick-actions__badge coach-quick-actions__badge--review"
            >
              {formatNumber.format(reviews.length)}
            </span>
          </Link>
          <Link href="/coach-area/peserta">
            <AppIcon name="people" variant="outline" />
            <strong>Peserta saya</strong>
            <span
              aria-label={`${formatNumber.format(needsAttention.length)} peserta perlu perhatian`}
              className="coach-quick-actions__badge coach-quick-actions__badge--attention"
            >
              {formatNumber.format(needsAttention.length)}
            </span>
          </Link>
          <Link href="/coach-area/program#aktivitas">
            <AppIcon name="content" variant="outline" />
            <strong>Aktivitas terbaru</strong>
          </Link>
          <Link href="/coach-area/program#peringkat">
            <AppIcon name="ranking" variant="outline" />
            <strong>Peringkat</strong>
          </Link>
          <Link href="/coach-area/program">
            <AppIcon name="program" variant="outline" />
            <strong>Program saya</strong>
          </Link>
          <Link href="/coach-area/qr">
            <AppIcon name="dashboard" variant="outline" />
            <strong>QR pendaftaran</strong>
          </Link>
        </nav>
      </section>
      <section aria-labelledby="coach-summary-title" className="coach-summary">
        <h2 id="coach-summary-title">Ringkasan pendampingan</h2>
        <Surface className="coach-metrics">
          <div>
            <AppIcon name="people" variant="outline" />
            <strong>{formatNumber.format(roster.length)}</strong>
            <span>Peserta saya</span>
          </div>
          <div>
            <AppIcon name="check" />
            <strong>{formatNumber.format(reviews.length)}</strong>
            <span>Perlu diperiksa</span>
          </div>
          <div>
            <AppIcon name="ranking" variant="outline" />
            <strong>{formatNumber.format(average)}%</strong>
            <span>Rata-rata progres</span>
          </div>
        </Surface>
      </section>
      <Link className="coach-participant-entry" href="/hari-ini">
        Ikuti program sebagai Peserta
      </Link>
      <section aria-labelledby="coach-programs-title">
        <h2 id="coach-programs-title">Program aktif</h2>
        <div className="coach-card-grid">
          {programs.length ? (
            programs.map((program) => (
              <Surface key={program.id}>
                <h3>{program.title}</h3>
                <p>{program.summary}</p>
                <Link href={`/coach-area/program?program=${program.id}`}>
                  Lihat aktivitas dan peringkat
                </Link>
              </Surface>
            ))
          ) : (
            <p>Belum ada program yang diikuti Peserta dampingan.</p>
          )}
        </div>
      </section>
      <section aria-labelledby="coach-attention-title">
        <h2 id="coach-attention-title">Perlu perhatian</h2>
        <div className="coach-list">
          {needsAttention.slice(0, 5).map((entry) => (
            <Link href={`/coach-area/peserta/${entry.participantId}`} key={entry.participantId}>
              <strong>{entry.displayName}</strong>
              <span>{attentionLabel(entry.attentionState)}</span>
            </Link>
          ))}
          {!needsAttention.length ? <p>Tidak ada perhatian baru.</p> : null}
        </div>
      </section>
      <section aria-labelledby="coach-activity-title">
        <h2 id="coach-activity-title">Aktivitas terbaru</h2>
        <div className="coach-list">
          {activity.map((item) => (
            <Link
              href={`/coach-area/peserta/${item.participantId}?program=${item.programId}`}
              key={item.id}
            >
              <strong>{item.participantName}</strong>
              <span>{item.stepTitle ?? item.programTitle}</span>
            </Link>
          ))}
          {!activity.length ? <p>Belum ada aktivitas.</p> : null}
        </div>
      </section>
      <section aria-labelledby="coach-dashboard-ranking-title">
        <h2 id="coach-dashboard-ranking-title">Papan peringkat</h2>
        {programs[0] ? <p>{programs[0].title} · bidang publik aman</p> : null}
        <ol className="coach-ranking-list coach-ranking-list--full">
          {leaderboard.map((entry) => (
            <li key={entry.id}>
              <strong>{formatNumber.format(entry.rank)}</strong>
              <div>
                <span>{entry.participantDisplayName}</span>
                <Progress
                  label={`Progres ${entry.participantDisplayName}`}
                  value={entry.progressPercentage}
                />
              </div>
              <span>{formatNumber.format(entry.totalPoints)} poin</span>
              {assignedIds.has(entry.participantId) ? (
                <StatusBadge tone="info">Peserta saya</StatusBadge>
              ) : null}
            </li>
          ))}
        </ol>
        {!leaderboard.length ? <p>Belum ada skor publik untuk program aktif.</p> : null}
      </section>
    </div>
  );
}

export function attentionLabel(state: CoachRosterEntry["attentionState"]) {
  return state === "not_enrolled"
    ? "Belum terdaftar"
    : state === "not_started"
      ? "Belum mulai"
      : state === "falling_behind"
        ? "Tertinggal"
        : state === "complete"
          ? "Selesai"
          : "Sesuai progres";
}

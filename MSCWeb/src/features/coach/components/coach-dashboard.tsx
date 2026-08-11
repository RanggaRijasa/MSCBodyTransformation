import Link from "next/link";

import type {
  CoachActivityItem,
  CoachContext,
  CoachReviewItem,
  CoachRosterEntry,
} from "@/domain/coach/coach-experience";
import type { PublicLeaderboardEntry } from "@/domain/participant/participant-program";
import type { PublicProgram } from "@/domain/programs/program";
import {
  createProgramDateTimeFormatter,
  formatNumber,
} from "@/shared/formatting/indonesian-formatters";
import { Avatar, Progress, StatusBadge, Surface } from "@/shared/ui";
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
      <header className="coach-identity-header">
        <Avatar
          {...(context.avatarUrl ? { imageUrl: context.avatarUrl } : {})}
          name={context.displayName}
          size={64}
        />
        <div>
          <p className="coach-eyebrow">Dashboard Coach</p>
          <h1>Halo, {context.displayName}</h1>
          <p>
            Akses aktif untuk mendampingi Peserta
            {context.accessEndsAt
              ? ` sampai ${createProgramDateTimeFormatter("Asia/Jakarta").format(new Date(context.accessEndsAt))} WIB`
              : ""}
            .
          </p>
        </div>
        <StatusBadge tone="success">Coach aktif</StatusBadge>
      </header>
      <section aria-label="Ringkasan Coach" className="coach-metrics">
        <Surface>
          <strong>{formatNumber.format(roster.length)}</strong>
          <span>Peserta saya</span>
        </Surface>
        <Surface>
          <strong>{formatNumber.format(reviews.length)}</strong>
          <span>Perlu diperiksa</span>
        </Surface>
        <Surface>
          <strong>{formatNumber.format(needsAttention.length)}</strong>
          <span>Perlu perhatian</span>
        </Surface>
        <Surface>
          <strong>{formatNumber.format(average)}%</strong>
          <span>Rata-rata progres</span>
        </Surface>
      </section>
      <nav aria-label="Tindakan cepat Coach" className="coach-quick-actions">
        <Link href="/coach-area/peserta">
          Peserta saya <span>{formatNumber.format(needsAttention.length)} perhatian</span>
        </Link>
        <Link href="/coach-area/pemeriksaan">
          Pemeriksaan <span>{formatNumber.format(reviews.length)} menunggu</span>
        </Link>
        <Link href="/coach-area/qr">Tampilkan QR Coach</Link>
        <Link href="/hari-ini">Ikuti program sebagai Peserta</Link>
      </nav>
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
        <ol className="participant-ranking-list participant-ranking-list--full">
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

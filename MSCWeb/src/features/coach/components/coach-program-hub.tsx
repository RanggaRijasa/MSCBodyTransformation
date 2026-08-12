import Link from "next/link";

import type { CoachContext, CoachProgramHub } from "@/domain/coach/coach-experience";
import {
  createProgramDateTimeFormatter,
  formatNumber,
} from "@/shared/formatting/indonesian-formatters";
import { Progress, StatusBadge, Surface } from "@/shared/ui";
import { CoachAccessState } from "./coach-access-state";

const activityCopy = {
  participant_joined: "bergabung ke program",
  program_completed: "menyelesaikan program",
  step_completed: "menyelesaikan langkah",
  submission_pending: "mengirim aktivitas untuk diperiksa",
  submission_rejected: "memiliki aktivitas yang perlu diperbaiki",
} as const;

export function CoachProgramHubView({
  context,
  hub,
  range,
}: Readonly<{
  context: CoachContext;
  hub: CoachProgramHub;
  range: string;
}>) {
  if (context.accessState !== "active") return <CoachAccessState context={context} />;
  return (
    <div className="coach-program-hub">
      <header>
        <p className="coach-eyebrow">Program dan aktivitas</p>
        <h1>Pendampingan program</h1>
        <p>Feed dan papan peringkat tidak menampilkan berat badan atau foto bukti.</p>
      </header>
      <nav aria-label="Pilih program" className="coach-program-strip">
        {hub.programs.map((program) => (
          <Link
            aria-current={program.id === hub.selectedProgram?.id ? "page" : undefined}
            className="coach-program-chip"
            href={`/coach-area/program?program=${program.id}&rentang=${range}`}
            key={program.id}
          >
            {program.title}
          </Link>
        ))}
      </nav>
      <nav aria-label="Rentang aktivitas" className="coach-range-filter">
        <Link
          aria-current={range === "1" ? "page" : undefined}
          href={`/coach-area/program?${hub.selectedProgram ? `program=${hub.selectedProgram.id}&` : ""}rentang=1`}
        >
          Hari ini
        </Link>
        <Link
          aria-current={range === "7" ? "page" : undefined}
          href={`/coach-area/program?${hub.selectedProgram ? `program=${hub.selectedProgram.id}&` : ""}rentang=7`}
        >
          7 hari
        </Link>
        <Link
          aria-current={range === "30" ? "page" : undefined}
          href={`/coach-area/program?${hub.selectedProgram ? `program=${hub.selectedProgram.id}&` : ""}rentang=30`}
        >
          30 hari
        </Link>
      </nav>
      <section aria-labelledby="aktivitas">
        <h2 id="aktivitas">Aktivitas</h2>
        <div className="coach-activity-feed">
          {hub.activity.map((item) => (
            <Surface key={item.id}>
              <div>
                <strong>{item.participantName}</strong>
                <p>
                  {activityCopy[item.kind]}
                  {item.stepTitle ? `: ${item.stepTitle}` : ""}
                </p>
                <small>{item.programTitle}</small>
              </div>
              {item.points !== null ? (
                <StatusBadge tone="success">+{formatNumber.format(item.points)} poin</StatusBadge>
              ) : null}
              <time dateTime={item.occurredAt}>
                {createProgramDateTimeFormatter("Asia/Jakarta").format(new Date(item.occurredAt))}{" "}
                WIB
              </time>
            </Surface>
          ))}
          {!hub.activity.length ? (
            <Surface>
              <h3>Belum ada aktivitas</h3>
              <p>Pilih rentang lebih panjang untuk melihat aktivitas sebelumnya.</p>
            </Surface>
          ) : null}
        </div>
      </section>
      <section aria-labelledby="peringkat">
        <h2 id="peringkat">Papan peringkat</h2>
        {hub.winners.length ? <p>Hasil final telah dikunci server.</p> : null}
        <ol className="coach-ranking-list coach-ranking-list--full">
          {hub.leaderboard.map((entry) => (
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
              {hub.assignedPublicProfileIds.has(entry.participantId) ? (
                <StatusBadge tone="info">Peserta saya</StatusBadge>
              ) : null}
            </li>
          ))}
        </ol>
        {!hub.leaderboard.length ? <p>Belum ada skor publik untuk program ini.</p> : null}
      </section>
      <Surface className="coach-participant-mode">
        <h2>Ikuti program sebagai Peserta</h2>
        <p>
          Gunakan perjalanan Peserta yang sama; progres pribadimu terpisah dari dashboard
          pendampingan.
        </p>
        <Link className="app-action app-action--secondary" href="/program">
          Buka katalog Peserta
        </Link>
      </Surface>
    </div>
  );
}

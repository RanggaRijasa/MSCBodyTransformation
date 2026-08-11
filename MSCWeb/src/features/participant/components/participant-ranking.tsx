import Link from "next/link";

import type {
  ParticipantProgram,
  PublicLeaderboardEntry,
  PublicWinner,
} from "@/domain/participant/participant-program";
import { formatNumber } from "@/shared/formatting/indonesian-formatters";
import { Progress, StatusBadge, Surface } from "@/shared/ui";
import { ProgramNetworkStatus } from "@/features/programs";

export function ParticipantRanking({
  currentEntry,
  entries,
  hasNextPage,
  page,
  programs,
  selected,
  winners,
}: Readonly<{
  currentEntry: PublicLeaderboardEntry | null;
  entries: readonly PublicLeaderboardEntry[];
  hasNextPage: boolean;
  page: number;
  programs: readonly ParticipantProgram[];
  selected: ParticipantProgram | null;
  winners: readonly PublicWinner[];
}>) {
  return (
    <div className="participant-ranking">
      <header>
        <h1>Papan peringkat</h1>
        <p>Poin dan progres publik tanpa menampilkan data berat badan.</p>
      </header>
      <ProgramNetworkStatus />
      {programs.length > 1 ? (
        <nav aria-label="Pilih program" className="participant-program-strip">
          {programs.map(({ program }) => (
            <Link
              aria-current={program.id === selected?.program.id ? "page" : undefined}
              className="participant-program-chip"
              href={`/peringkat?program=${program.id}`}
              key={program.id}
            >
              {program.title}
              <span>
                {["archived", "completed"].includes(program.status) ? "Riwayat" : "Aktif"}
              </span>
            </Link>
          ))}
        </nav>
      ) : null}
      {!selected ? (
        <Surface>
          <h2>Belum ada program</h2>
          <p>Peringkat tersedia setelah enrollment aktif.</p>
        </Surface>
      ) : (
        <>
          <Surface className="participant-ranking__summary">
            <div>
              <h2>{selected.program.title}</h2>
              <p>Urutan stabil berdasarkan skor resmi server.</p>
            </div>
            <div>
              <strong>{formatNumber.format(selected.score.totalPoints)}</strong>
              <span>
                {currentEntry ? `Peringkat ${formatNumber.format(currentEntry.rank)}` : "poinmu"}
              </span>
            </div>
          </Surface>
          {currentEntry && !entries.some(({ id }) => id === currentEntry.id) ? (
            <Surface className="participant-current-rank">
              <span>Posisimu</span>
              <strong>Peringkat {formatNumber.format(currentEntry.rank)}</strong>
              <span>{formatNumber.format(currentEntry.totalPoints)} poin</span>
            </Surface>
          ) : null}
          {winners.length ? (
            <section aria-labelledby="ranking-winners">
              <h2 id="ranking-winners">Hasil yang dikunci</h2>
              <ol className="participant-ranking-list">
                {winners.map((winner) => (
                  <li className={`rank-${winner.rank}`} key={winner.id}>
                    <strong>{formatNumber.format(winner.rank)}</strong>
                    <span>{winner.participantDisplayName}</span>
                    <span>{formatNumber.format(winner.totalPoints)} poin</span>
                  </li>
                ))}
              </ol>
            </section>
          ) : null}
          <section aria-labelledby="ranking-all">
            <h2 id="ranking-all">Peringkat peserta</h2>
            {entries.length ? (
              <ol className="participant-ranking-list participant-ranking-list--full">
                {entries.map((entry) => (
                  <li
                    className={
                      `${entry.isCurrentParticipant ? "is-current " : ""}${entry.rank <= 5 ? `rank-${entry.rank}` : ""}`.trim() ||
                      undefined
                    }
                    key={entry.id}
                  >
                    <strong>{formatNumber.format(entry.rank)}</strong>
                    <div>
                      <span>{entry.participantDisplayName}</span>
                      <Progress
                        label={`Progres ${entry.participantDisplayName}`}
                        value={entry.progressPercentage}
                      />
                    </div>
                    <span>{formatNumber.format(entry.totalPoints)} poin</span>
                    {entry.isCurrentParticipant ? (
                      <StatusBadge tone="info">Kamu</StatusBadge>
                    ) : null}
                  </li>
                ))}
              </ol>
            ) : (
              <p>Poin server belum tersedia untuk program ini.</p>
            )}
            {entries.length ? (
              <nav aria-label="Halaman papan peringkat" className="participant-pagination">
                {page > 1 ? (
                  <Link href={`/peringkat?program=${selected.program.id}&page=${page - 1}`}>
                    Sebelumnya
                  </Link>
                ) : (
                  <span />
                )}
                <span>Halaman {formatNumber.format(page)}</span>
                {hasNextPage ? (
                  <Link href={`/peringkat?program=${selected.program.id}&page=${page + 1}`}>
                    Berikutnya
                  </Link>
                ) : (
                  <span />
                )}
              </nav>
            ) : null}
          </section>
        </>
      )}
    </div>
  );
}

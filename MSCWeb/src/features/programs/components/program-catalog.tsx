import type { CatalogSections } from "@/domain/programs/program-catalog";
import type { PublicProgram } from "@/domain/programs/program";
import { ProgramCard } from "@/features/programs/components/program-card";
import { ProgramNetworkStatus } from "@/features/programs/components/program-network-status";
import { StateMessage } from "@/shared/ui";

function ProgramCollection({
  emptyCopy,
  now,
  programs,
  relationship,
  title,
}: Readonly<{
  emptyCopy: string;
  now: Date;
  programs: readonly PublicProgram[];
  relationship: "available" | "followed" | "history";
  title: string;
}>) {
  return (
    <section aria-labelledby={`program-section-${relationship}`}>
      <h2 id={`program-section-${relationship}`}>{title}</h2>
      {programs.length === 0 ? (
        <p className="program-section-empty">{emptyCopy}</p>
      ) : (
        <div className="program-grid">
          {programs.map((program) => (
            <ProgramCard key={program.id} now={now} program={program} relationship={relationship} />
          ))}
        </div>
      )}
    </section>
  );
}

export function ProgramCatalog({
  isAuthenticatedParticipant,
  now,
  sections,
}: Readonly<{
  isAuthenticatedParticipant: boolean;
  now: Date;
  sections: CatalogSections;
}>) {
  const followed = sections.followed.map(({ program }) => program);
  const hasAny = followed.length + sections.available.length + sections.history.length > 0;
  return (
    <div className="program-page">
      <header className="program-page__header">
        <p className="program-eyebrow">Program MSC</p>
        <h1>Temukan program transformasimu</h1>
        <p>Pilih program, lihat jadwal dan ketentuannya, lalu daftar dengan QR Coach.</p>
      </header>
      <ProgramNetworkStatus />
      {!hasAny ? (
        <StateMessage
          description="Belum ada program publik yang dapat ditampilkan. Coba lagi nanti."
          title="Program belum tersedia"
        />
      ) : null}
      {isAuthenticatedParticipant ? (
        <ProgramCollection
          emptyCopy="Belum ada program yang kamu ikuti."
          now={now}
          programs={followed}
          relationship="followed"
          title="Diikuti"
        />
      ) : null}
      <ProgramCollection
        emptyCopy="Belum ada program yang tersedia untuk pendaftaran."
        now={now}
        programs={sections.available}
        relationship="available"
        title="Tersedia"
      />
      <ProgramCollection
        emptyCopy="Belum ada program dalam riwayat."
        now={now}
        programs={sections.history}
        relationship="history"
        title="Riwayat"
      />
    </div>
  );
}

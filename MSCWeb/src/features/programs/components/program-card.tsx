import type { PublicProgram } from "@/domain/programs/program";
import { evaluateProgramOffer } from "@/domain/programs/program-catalog";
import {
  formatCurrencyIDR,
  formatProgramDate,
  programTimezoneLabel,
} from "@/shared/formatting/indonesian-formatters";
import { AppLink, MediaSurface, StatusBadge, Surface } from "@/shared/ui";

function statusPresentation(program: PublicProgram, now: Date) {
  const offer = evaluateProgramOffer(program, now);
  if (offer === "registration_closed")
    return { label: "Pendaftaran ditutup", tone: "warning" as const };
  switch (program.status) {
    case "scheduled":
      return { label: "Akan datang", tone: "info" as const };
    case "active":
      return { label: "Sedang berjalan", tone: "success" as const };
    case "completed":
      return { label: "Selesai", tone: "neutral" as const };
    case "archived":
      return { label: "Riwayat", tone: "neutral" as const };
  }
}

export function ProgramCard({
  now,
  program,
  relationship,
}: Readonly<{
  now: Date;
  program: PublicProgram;
  relationship: "available" | "followed" | "history";
}>) {
  const status = statusPresentation(program, now);
  const price =
    program.pricingMode === "free"
      ? "Gratis"
      : formatCurrencyIDR.format(Number(program.desiredPrice));
  return (
    <Surface className="program-card">
      <MediaSurface
        alt={program.coverAlternativeText ?? `Cover ${program.title}`}
        {...(program.coverImageUrl ? { src: program.coverImageUrl } : {})}
      />
      <div className="program-card__body">
        <div className="program-card__status">
          <StatusBadge tone={status.tone}>{status.label}</StatusBadge>
          <strong>{price}</strong>
        </div>
        <div>
          <p className="program-card__category">{program.category}</p>
          <h3>{program.title}</h3>
          <p>{program.summary}</p>
        </div>
        <p className="program-card__period">
          {formatProgramDate(program.startsOn, program.timezone)}–
          {formatProgramDate(program.endsOn, program.timezone)} ·{" "}
          {programTimezoneLabel(program.timezone)}
        </p>
        <AppLink
          href={`/program/${program.id}`}
          variant={relationship === "followed" ? "primary" : "secondary"}
        >
          {relationship === "followed" ? "Buka program" : "Lihat detail"}
        </AppLink>
      </div>
    </Surface>
  );
}

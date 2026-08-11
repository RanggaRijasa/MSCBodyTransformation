import type { PublicProgram, ProgramContentKind } from "@/domain/programs/program";
import { evaluateProgramOffer } from "@/domain/programs/program-catalog";
import {
  createProgramDateTimeFormatter,
  formatCurrencyIDR,
  formatNumber,
  formatProgramDate,
  programTimezoneLabel,
} from "@/shared/formatting/indonesian-formatters";
import { AppLink, MediaSurface, Metric, StatusBadge, Surface } from "@/shared/ui";

const serviceLabels: Readonly<Record<ProgramContentKind, string>> = {
  article: "Panduan artikel",
  daily_weigh_in: "Pencatatan berat harian",
  final_weigh_in: "Pencatatan berat akhir",
  form: "Refleksi dan formulir",
  initial_weigh_in: "Pencatatan berat awal",
  quiz: "Kuis pemahaman",
  video: "Video aktivitas",
};

function services(program: PublicProgram): readonly string[] {
  return [
    ...new Set(
      program.days.flatMap((day) => day.steps.map((step) => serviceLabels[step.contentKind])),
    ),
  ];
}

function JoinAction({
  actor,
  program,
}: Readonly<{ actor: "guest" | "participant" | "other"; program: PublicProgram }>) {
  if (actor === "participant") {
    return <AppLink href={`/program/${program.id}/gabung`}>Daftar dengan QR Coach</AppLink>;
  }
  if (actor === "guest") {
    return (
      <form action="/auth/intent/program" method="post">
        <input name="programId" type="hidden" value={program.id} />
        <button className="app-action app-action--primary" type="submit">
          <span>Masuk untuk mendaftar</span>
        </button>
      </form>
    );
  }
  return (
    <p className="program-detail__notice">Pendaftaran program hanya tersedia untuk Peserta.</p>
  );
}

export function ProgramDetail({
  actor,
  mode,
  now,
  program,
}: Readonly<{
  actor: "guest" | "participant" | "other";
  mode: "activity" | "offer";
  now: Date;
  program: PublicProgram;
}>) {
  const offerState = evaluateProgramOffer(program, now);
  const registrationClose = program.registrationClosesAt
    ? createProgramDateTimeFormatter(program.timezone).format(
        new Date(program.registrationClosesAt),
      )
    : "Tidak ada cutoff tambahan";
  const price =
    program.pricingMode === "free"
      ? "Gratis"
      : formatCurrencyIDR.format(Number(program.desiredPrice));
  const availableServices = services(program);
  const canJoin = mode === "offer" && offerState === "available";
  return (
    <article className="program-detail">
      <header className="program-detail__hero">
        <MediaSurface
          alt={program.coverAlternativeText ?? `Cover ${program.title}`}
          {...(program.coverImageUrl ? { src: program.coverImageUrl } : {})}
        />
        <div>
          <p className="program-eyebrow">{program.category}</p>
          <h1>{program.title}</h1>
          <p>{program.summary}</p>
          <div className="program-detail__badges">
            <StatusBadge tone={program.status === "active" ? "success" : "info"}>
              {program.status === "active"
                ? "Sedang berjalan"
                : program.status === "scheduled"
                  ? "Akan datang"
                  : "Selesai"}
            </StatusBadge>
            <StatusBadge tone="neutral">{price}</StatusBadge>
          </div>
          {mode === "activity" ? (
            <AppLink href={`/hari-ini?program=${program.id}`}>Buka aktivitas program</AppLink>
          ) : canJoin ? (
            <JoinAction actor={actor} program={program} />
          ) : (
            <p className="program-detail__closed" role="status">
              {offerState === "registration_closed"
                ? "Pendaftaran program ini sudah ditutup."
                : "Program ini sudah selesai dan tetap tersedia sebagai informasi."}
            </p>
          )}
        </div>
      </header>

      <section aria-labelledby="program-overview-title">
        <h2 id="program-overview-title">Ringkasan program</h2>
        <div className="program-detail__metrics">
          <Metric
            label="Periode"
            value={`${formatProgramDate(program.startsOn, program.timezone)}–${formatProgramDate(program.endsOn, program.timezone)}`}
          />
          <Metric label="Zona waktu" value={programTimezoneLabel(program.timezone)} />
          <Metric
            label="Kapasitas"
            value={
              program.participantLimit
                ? `Maksimal ${formatNumber.format(program.participantLimit)}`
                : "Tidak dibatasi"
            }
          />
          <Metric label="Pendaftaran ditutup" value={registrationClose} />
        </div>
      </section>

      <div className="program-detail__columns">
        <Surface>
          <h2>Yang kamu dapatkan</h2>
          {availableServices.length > 0 ? (
            <ul>
              {availableServices.map((service) => (
                <li key={service}>{service}</li>
              ))}
            </ul>
          ) : (
            <p>Rincian aktivitas akan diumumkan oleh Admin.</p>
          )}
          <p>Pendaftaran memerlukan QR dari Coach yang aktif dan disetujui.</p>
        </Surface>
        <Surface>
          <h2>Ringkasan poin</h2>
          <ul>
            <li>
              {formatNumber.format(program.pointsPerActivity)} poin per aktivitas yang disetujui
            </li>
            <li>
              {formatNumber.format(Number(program.pointsPerWeightKilogram))} poin per kilogram
              penurunan berat
            </li>
            <li>Kuis lulus mulai {formatNumber.format(program.quizPassingPercentage)}%</li>
          </ul>
          <p>Nilai dan penyelesaian akhir tetap divalidasi oleh server.</p>
        </Surface>
      </div>

      <Surface className="program-detail__wellness">
        <h2>Catatan kebugaran</h2>
        <p>
          {program.wellnessDisclaimer ||
            "Program ini bersifat kebugaran dan bukan layanan diagnosis medis."}
        </p>
      </Surface>
    </article>
  );
}

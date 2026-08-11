import Link from "next/link";

import type { CoachContext, CoachRosterEntry } from "@/domain/coach/coach-experience";
import type { PublicProgram } from "@/domain/programs/program";
import { formatNumber } from "@/shared/formatting/indonesian-formatters";
import {
  AppButton,
  Avatar,
  FilterForm,
  Progress,
  SelectField,
  StatusBadge,
  Surface,
  TextField,
} from "@/shared/ui";
import { CoachAccessState } from "./coach-access-state";
import { attentionLabel } from "./coach-dashboard";

export function CoachRoster({
  context,
  entries,
  filters,
  programs,
}: Readonly<{
  context: CoachContext;
  entries: readonly CoachRosterEntry[];
  filters: Readonly<{
    attention?: string | undefined;
    programId?: string | undefined;
    query?: string | undefined;
    sort?: string | undefined;
  }>;
  programs: readonly PublicProgram[];
}>) {
  if (context.accessState !== "active") return <CoachAccessState context={context} />;
  return (
    <div className="coach-roster">
      <header>
        <p className="coach-eyebrow">Pendampingan</p>
        <h1>Peserta saya</h1>
        <p>Daftar ini tidak menampilkan berat badan atau pratinjau bukti.</p>
      </header>
      <FilterForm className="coach-filters" method="get" role="search">
        <TextField
          defaultValue={filters.query}
          id="coach-roster-query"
          label="Cari Peserta"
          name="q"
          placeholder="Nama atau kota"
          type="search"
        />
        <SelectField
          defaultValue={filters.programId ?? ""}
          id="coach-roster-program"
          label="Program"
          name="program"
        >
          <option value="">Semua program</option>
          {programs.map((program) => (
            <option key={program.id} value={program.id}>
              {program.title}
            </option>
          ))}
        </SelectField>
        <SelectField
          defaultValue={filters.attention ?? ""}
          id="coach-roster-attention"
          label="Perhatian"
          name="perhatian"
        >
          <option value="">Semua status</option>
          <option value="not_enrolled">Belum terdaftar</option>
          <option value="not_started">Belum mulai</option>
          <option value="falling_behind">Tertinggal</option>
          <option value="on_track">Sesuai progres</option>
          <option value="complete">Selesai</option>
        </SelectField>
        <SelectField
          defaultValue={filters.sort ?? "progress"}
          id="coach-roster-sort"
          label="Urutkan"
          name="urut"
        >
          <option value="progress">Progres</option>
          <option value="points">Poin</option>
          <option value="activity">Aktivitas terakhir</option>
        </SelectField>
        <AppButton type="submit" variant="secondary">
          Terapkan
        </AppButton>
      </FilterForm>
      <p>{formatNumber.format(entries.length)} Peserta ditemukan</p>
      <div className="coach-roster__grid">
        {entries.map((entry) => (
          <Surface className="coach-roster-card" key={entry.participantId}>
            <div className="coach-roster-card__identity">
              <Avatar
                {...(entry.avatarUrl ? { imageUrl: entry.avatarUrl } : {})}
                name={entry.displayName}
              />
              <div>
                <h2>{entry.displayName}</h2>
                <p>{entry.city ?? "Kota belum diisi"}</p>
              </div>
            </div>
            <StatusBadge
              tone={
                entry.attentionState === "complete"
                  ? "success"
                  : entry.attentionState === "on_track"
                    ? "info"
                    : "warning"
              }
            >
              {attentionLabel(entry.attentionState)}
            </StatusBadge>
            <p>{entry.programTitle ?? "Belum memiliki enrollment program"}</p>
            <Progress label={`Progres ${entry.displayName}`} value={entry.progressPercentage} />
            <div className="coach-roster-card__metrics">
              <span>{formatNumber.format(entry.points)} poin</span>
              <span>{formatNumber.format(entry.pendingReviewCount)} menunggu</span>
            </div>
            <Link
              href={`/coach-area/peserta/${entry.participantId}${entry.programId ? `?program=${entry.programId}` : ""}`}
            >
              Buka detail privat
            </Link>
          </Surface>
        ))}
        {!entries.length ? (
          <Surface>
            <h2>Tidak ada hasil</h2>
            <p>Ubah pencarian atau filter untuk melihat Peserta lain.</p>
          </Surface>
        ) : null}
      </div>
    </div>
  );
}

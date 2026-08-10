import { shellProgramFixture } from "@/features/app-shell/fixtures/shell-fixtures";
import type { ShellKind } from "@/features/app-shell/model/navigation-items";
import { copy } from "@/shared/i18n/id";
import {
  AppLink,
  ListRow,
  Metric,
  ProgramActivityRenderer,
  SectionHeading,
  StatusBadge,
  Surface,
  type AppIconName,
  type ProgramActivityAudience,
} from "@/shared/ui";

type ShellPlaceholderProperties = Readonly<{
  audience?: ProgramActivityAudience;
  kind?: ShellKind;
  summary: string;
  title: string;
}>;

type RelatedLink = Readonly<{
  detail: string;
  href: string;
  icon: AppIconName;
  title: string;
}>;

const relatedLinks: Readonly<Record<ShellKind, readonly RelatedLink[]>> = {
  participant: [
    {
      detail: "Tujuan halaman contoh",
      href: "/program",
      icon: "program",
      title: "Buka katalog program",
    },
    {
      detail: "Data aman untuk publik",
      href: "/peringkat",
      icon: "ranking",
      title: "Buka papan peringkat",
    },
  ],
  coach: [
    {
      detail: "Roster dan perhatian",
      href: "/coach-area/peserta",
      icon: "people",
      title: "Peserta saya",
    },
    {
      detail: "Antrean jawaban",
      href: "/coach-area/pemeriksaan",
      icon: "check",
      title: "Buka pemeriksaan",
    },
    {
      detail: "Enrollment Peserta",
      href: "/coach-area/qr",
      icon: "info",
      title: "Tampilkan QR Coach",
    },
  ],
  admin: [
    {
      detail: "Draft dan publikasi",
      href: "/admin/program",
      icon: "program",
      title: "Kelola program",
    },
    {
      detail: "Peserta, Coach, dan Admin",
      href: "/admin/orang",
      icon: "people",
      title: "Buka direktori orang",
    },
  ],
};

export function ShellPlaceholder({
  audience = "participant",
  kind = "participant",
  summary,
  title,
}: ShellPlaceholderProperties) {
  return (
    <div className="shell-page">
      <header className="shell-page__header">
        <p>{copy.shell.phaseLabel}</p>
        <h1>{title}</h1>
        <p>{summary}</p>
      </header>

      <div className="shell-page__metrics" aria-label="Ringkasan fixture">
        <Metric label="Aktivitas tersedia" value="3" />
        <Metric label="Progres contoh" value="40%" />
        <Surface>
          <StatusBadge tone="info">Data contoh lokal</StatusBadge>
          <p>{copy.shell.placeholderMessage}</p>
        </Surface>
      </div>

      <SectionHeading
        subtitle="Hierarki yang sama digunakan oleh Peserta, Coach, dan pratinjau Admin."
        title={copy.stateGallery.program}
      />
      <ProgramActivityRenderer audience={audience} model={shellProgramFixture} />

      <section aria-labelledby="quick-actions-title">
        <SectionHeading title="Tujuan terkait" />
        <Surface className="shell-page__list">
          {relatedLinks[kind].map((link) => (
            <ListRow {...link} key={link.href} />
          ))}
        </Surface>
      </section>

      <AppLink href="/" variant="secondary">
        Kembali ke fondasi
      </AppLink>
    </div>
  );
}

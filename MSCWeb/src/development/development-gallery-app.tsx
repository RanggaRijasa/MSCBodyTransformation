import { AdminGallery } from "@/development/admin-gallery";
import { CoachGallery } from "@/development/coach-gallery";
import { GuestGallery } from "@/development/guest-gallery";
import { ParticipantGallery } from "@/development/participant-gallery";
import { StateGallery } from "@/development/state-gallery";
import { AppShell } from "@/features/app-shell/components/app-shell";
import type { ShellKind } from "@/features/app-shell/model/navigation-items";

export type DevelopmentView = "all" | "guest" | "participant" | "coach" | "admin";

export const developmentViewLabels: Readonly<Record<DevelopmentView, string>> = {
  all: "Semua kondisi",
  guest: "Guest",
  participant: "Peserta",
  coach: "Coach",
  admin: "Admin",
};

const developmentViews: readonly Readonly<{
  href: string;
  id: DevelopmentView;
}>[] = [
  { href: "/", id: "all" },
  { href: "/?view=guest", id: "guest" },
  { href: "/?view=participant", id: "participant" },
  { href: "/?view=coach", id: "coach" },
  { href: "/?view=admin", id: "admin" },
];

const knownDevelopmentViews = new Set<DevelopmentView>([
  "all",
  "guest",
  "participant",
  "coach",
  "admin",
]);

export function developmentViewFromSearch(search: string): DevelopmentView {
  const candidate = new URLSearchParams(search).get("view") ?? "all";
  return knownDevelopmentViews.has(candidate as DevelopmentView)
    ? (candidate as DevelopmentView)
    : "all";
}

function DevelopmentToolbar({ selectedView }: Readonly<{ selectedView: DevelopmentView }>) {
  return (
    <header className="development-viewer__toolbar">
      <div className="development-viewer__identity">
        <strong>MSC development</strong>
        <span>Fixture lokal aman · tidak tersedia pada production</span>
      </div>
      <nav aria-label="Halaman role development" className="development-viewer__navigation">
        {developmentViews.map(({ href, id }) => (
          <a aria-current={selectedView === id ? "page" : undefined} href={href} key={id}>
            {developmentViewLabels[id]}
          </a>
        ))}
      </nav>
    </header>
  );
}

function DevelopmentRolePage({
  selectedView,
}: Readonly<{ selectedView: Exclude<DevelopmentView, "all"> }>) {
  const shellKind: ShellKind =
    selectedView === "guest" || selectedView === "participant" ? "participant" : selectedView;

  return (
    <AppShell kind={shellKind} label={`${developmentViewLabels[selectedView]} development`}>
      <div className="development-viewer__role-content">
        <p className="development-viewer__notice" role="status">
          Pratinjau ini memakai data fixture lokal. Tindakan dan tautan tidak mengubah data
          produksi.
        </p>
        {selectedView === "guest" ? <GuestGallery /> : null}
        {selectedView === "participant" ? <ParticipantGallery /> : null}
        {selectedView === "coach" ? <CoachGallery /> : null}
        {selectedView === "admin" ? <AdminGallery /> : null}
      </div>
    </AppShell>
  );
}

export function DevelopmentGalleryApp({
  selectedView,
}: Readonly<{ selectedView: DevelopmentView }>) {
  if (selectedView === "all") {
    return <StateGallery />;
  }

  return (
    <div className="development-viewer" data-development-view={selectedView}>
      <DevelopmentToolbar selectedView={selectedView} />
      <DevelopmentRolePage selectedView={selectedView} />
    </div>
  );
}

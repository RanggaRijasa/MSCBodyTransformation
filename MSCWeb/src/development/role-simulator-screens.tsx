import { useState } from "react";

import { adminSimulatorDashboard, adminSimulatorPrograms } from "@/development/admin-gallery";
import {
  coachSimulatorActivity,
  coachSimulatorContext,
  coachSimulatorProgram,
  coachSimulatorReviews,
  coachSimulatorRoster,
} from "@/development/coach-gallery";
import {
  coachSimulatorHub,
  coachSimulatorParticipantDetail,
  participantSimulatorRanking,
  simulatorProgramSections,
} from "@/development/role-simulator-fixtures";
import {
  guestSimulatorCoaches,
  guestSimulatorProgram,
  guestSimulatorRanking,
} from "@/development/guest-gallery";
import {
  participantSimulatorEnrollment,
  participantSimulatorProgram,
} from "@/development/participant-gallery";
import { AdminDashboard } from "@/features/admin/components/admin-dashboard";
import { AdminProgramList } from "@/features/admin/components/admin-program-list";
import { AdminSettings } from "@/features/admin/components/admin-settings";
import { CoachDashboard } from "@/features/coach/components/coach-dashboard";
import { CoachParticipantDetailView } from "@/features/coach/components/coach-participant-detail";
import { CoachProgramHubView } from "@/features/coach/components/coach-program-hub";
import { CoachRoster } from "@/features/coach/components/coach-roster";
import { CoachDirectory } from "@/features/participant/components/coach-directory";
import { ParticipantHome } from "@/features/participant/components/participant-home";
import { ParticipantRanking } from "@/features/participant/components/participant-ranking";
import { ProgramActivity } from "@/features/participant/components/program-activity";
import { ProgramCatalog } from "@/features/programs/components/program-catalog";
import { ProgramDetail } from "@/features/programs/components/program-detail";
import { AppButton, AppIcon, AppLink, ListRow, StatusBadge, Surface, TextField } from "@/shared/ui";

export type SimulatorRole = "guest" | "participant" | "coach" | "admin";

const participantCoaches = guestSimulatorCoaches.map((coach) => ({ ...coach, isAssigned: true }));

export function ParticipantSimulatorScreen({
  pathname,
  role,
}: Readonly<{ pathname: string; role: SimulatorRole }>) {
  const isGuest = role === "guest";
  if (pathname === "/program") {
    return (
      <ProgramCatalog
        isAuthenticatedParticipant={!isGuest}
        now={new Date("2026-08-12T08:00:00+08:00")}
        sections={
          isGuest ? { ...simulatorProgramSections, followed: [] } : simulatorProgramSections
        }
      />
    );
  }
  if (pathname.startsWith("/program/") && pathname.includes("/langkah/")) {
    return <ProgramActivity participantProgram={participantSimulatorEnrollment} />;
  }
  if (pathname.startsWith("/program/")) {
    return (
      <ProgramDetail
        actor={isGuest ? "guest" : "participant"}
        mode="offer"
        now={new Date("2026-08-12T08:00:00+08:00")}
        program={isGuest ? guestSimulatorProgram : participantSimulatorProgram}
      />
    );
  }
  if (pathname === "/peringkat") {
    return (
      <ParticipantRanking
        currentEntry={isGuest ? null : participantSimulatorRanking[1]!}
        entries={isGuest ? guestSimulatorRanking : participantSimulatorRanking}
        hasNextPage={false}
        page={1}
        programs={isGuest ? [] : [participantSimulatorEnrollment]}
        selected={isGuest ? null : participantSimulatorEnrollment}
        winners={[]}
      />
    );
  }
  if (pathname === "/coach") {
    return <CoachDirectory coaches={isGuest ? guestSimulatorCoaches : participantCoaches} />;
  }
  if (pathname === "/profil") return <DevelopmentProfile role={role} />;
  return (
    <ParticipantHome
      actor={isGuest ? "guest" : "participant"}
      coaches={isGuest ? guestSimulatorCoaches : participantCoaches}
      displayName={isGuest ? "" : "Rani"}
      programs={isGuest ? [] : [participantSimulatorEnrollment]}
      publicPrograms={isGuest ? [guestSimulatorProgram] : []}
      selectedProgram={isGuest ? null : participantSimulatorEnrollment}
      topFive={isGuest ? guestSimulatorRanking : participantSimulatorRanking}
      winnerPosters={[]}
      winners={[]}
    />
  );
}

export function CoachSimulatorScreen({ pathname }: Readonly<{ pathname: string }>) {
  if (pathname === "/coach-area/program") {
    return (
      <CoachProgramHubView context={coachSimulatorContext} hub={coachSimulatorHub} range="7" />
    );
  }
  if (pathname === "/coach-area/peserta") {
    return (
      <CoachRoster
        context={coachSimulatorContext}
        entries={coachSimulatorRoster}
        filters={{}}
        programs={[coachSimulatorProgram]}
      />
    );
  }
  if (pathname.startsWith("/coach-area/peserta/")) {
    return <CoachParticipantDetailView detail={coachSimulatorParticipantDetail} />;
  }
  if (pathname === "/coach-area/pemeriksaan") return <DevelopmentReviewScreen />;
  if (pathname === "/coach-area/qr") return <DevelopmentCoachQr />;
  if (pathname === "/coach-area/profil") return <DevelopmentProfile role="coach" />;
  return (
    <CoachDashboard
      activity={coachSimulatorActivity}
      context={coachSimulatorContext}
      leaderboard={participantSimulatorRanking}
      programs={[coachSimulatorProgram]}
      reviews={coachSimulatorReviews}
      roster={coachSimulatorRoster}
    />
  );
}

export function AdminSimulatorScreen({ pathname }: Readonly<{ pathname: string }>) {
  if (pathname === "/admin/program") {
    return <AdminProgramList items={adminSimulatorPrograms} query="" status="" />;
  }
  if (pathname.startsWith("/admin/program/")) return <DevelopmentProgramEditor />;
  if (pathname === "/admin/orang") return <DevelopmentPeople />;
  if (pathname === "/admin/konten") return <DevelopmentContent />;
  if (pathname === "/admin/pengaturan") {
    return (
      <AdminSettings
        audit={adminSimulatorDashboard.recentAudit}
        environment="development lokal"
        siteUrl="http://127.0.0.1:4174"
      />
    );
  }
  if (pathname.startsWith("/admin/pembayaran")) return <DevelopmentPayments />;
  return <AdminDashboard snapshot={adminSimulatorDashboard} />;
}

function DevelopmentProfile({ role }: Readonly<{ role: SimulatorRole }>) {
  const [saved, setSaved] = useState(false);
  return (
    <div className="role-simulator-page">
      <header>
        <h1>Profil</h1>
        <p>Data berikut hanya hidup di simulator development.</p>
      </header>
      <Surface className="role-simulator-form">
        <div className="role-simulator-identity">
          <AppIcon name="person" />
          <div>
            <strong>{role === "coach" ? "Coach Ayu" : "Rani Putri"}</strong>
            <span>{role === "coach" ? "Coach aktif" : "Peserta aktif"}</span>
          </div>
        </div>
        <TextField
          defaultValue={role === "coach" ? "Coach Ayu" : "Rani Putri"}
          id="simulator-name"
          label="Nama tampilan"
        />
        <TextField defaultValue="0812 3456 7890" id="simulator-phone" label="Nomor HP" />
        <AppButton onClick={() => setSaved(true)}>Simpan perubahan</AppButton>
        {saved ? <p role="status">Perubahan simulasi tersimpan di halaman ini.</p> : null}
      </Surface>
    </div>
  );
}

function DevelopmentReviewScreen() {
  const [state, setState] = useState<"pending" | "approved" | "rejected">("pending");
  return (
    <div className="role-simulator-page">
      <header>
        <h1>Pemeriksaan</h1>
        <p>Periksa jawaban Peserta tanpa mengirim keputusan ke server.</p>
      </header>
      <Surface className="role-simulator-review">
        <div>
          <StatusBadge
            tone={state === "pending" ? "warning" : state === "approved" ? "success" : "error"}
          >
            {state === "pending"
              ? "Menunggu pemeriksaan"
              : state === "approved"
                ? "Disetujui"
                : "Perlu diperbaiki"}
          </StatusBadge>
          <h2>Rani Putri</h2>
          <p>Refleksi kebiasaan · MSC Agustus</p>
        </div>
        <blockquote>“Saya menyiapkan jadwal aktivitas yang realistis untuk besok.”</blockquote>
        <div className="role-simulator-actions">
          <AppButton onClick={() => setState("approved")}>Setujui simulasi</AppButton>
          <AppButton onClick={() => setState("rejected")} variant="secondary">
            Minta perbaikan
          </AppButton>
        </div>
      </Surface>
    </div>
  );
}

function DevelopmentCoachQr() {
  return (
    <div className="role-simulator-page">
      <header>
        <h1>QR Coach</h1>
        <p>Pratinjau aman untuk alur pendaftaran lokal.</p>
      </header>
      <Surface className="role-simulator-qr">
        <div aria-label="Pratinjau QR Coach" className="role-simulator-qr__image">
          <AppIcon name="dashboard" />
        </div>
        <h2>QR pendaftaran Coach Ayu</h2>
        <p>
          Pindai dari perjalanan Peserta untuk mencoba komposisi alur. Simulator tidak menampilkan
          identifier mentah.
        </p>
        <AppButton onClick={() => navigator.clipboard?.writeText("Simulasi QR Coach")}>
          Salin label simulasi
        </AppButton>
      </Surface>
    </div>
  );
}

function DevelopmentPeople() {
  return (
    <div className="role-simulator-page">
      <header>
        <h1>Orang</h1>
        <p>Direktori lokal dengan peran server sebagai referensi.</p>
      </header>
      <Surface>
        {[
          { title: "Rani Putri", detail: "Peserta · Member" },
          { title: "Coach Ayu", detail: "Coach · SC" },
          { title: "Admin MSC", detail: "Admin · Operasional" },
        ].map((person) => (
          <ListRow detail={person.detail} icon="person" key={person.title} title={person.title} />
        ))}
      </Surface>
    </div>
  );
}

function DevelopmentContent() {
  return (
    <div className="role-simulator-page">
      <header>
        <h1>Konten</h1>
        <p>Kelola poster pemenang dan konten aplikasi.</p>
      </header>
      <div className="role-simulator-card-grid">
        <Surface>
          <div className="role-simulator-poster">
            <AppIcon name="content" />
          </div>
          <h2>Poster pemenang Agustus</h2>
          <StatusBadge tone="success">Diterbitkan</StatusBadge>
        </Surface>
        <Surface>
          <h2>Tambahkan poster</h2>
          <p>Pemilih media asli dinonaktifkan di simulator aman.</p>
          <AppButton onClick={() => undefined} variant="secondary">
            Pilih media
          </AppButton>
        </Surface>
      </div>
    </div>
  );
}

function DevelopmentPayments() {
  return (
    <div className="role-simulator-page">
      <header>
        <h1>Pembayaran</h1>
        <p>Antrean privat menggunakan identitas sintetis.</p>
      </header>
      <Surface>
        <ListRow
          detail="MSC Agustus · Rp250.000 · Menunggu pemeriksaan"
          href="/admin/pembayaran/simulator-order"
          icon="payment"
          title="Rani Putri"
        />
        <ListRow
          detail="Akses Coach · Rp100.000 · Perlu perbaikan"
          icon="payment"
          title="Dewi Lestari"
        />
      </Surface>
    </div>
  );
}

function DevelopmentProgramEditor() {
  const [saved, setSaved] = useState(false);
  return (
    <div className="role-simulator-page">
      <header>
        <h1>Editor program</h1>
        <p>Perubahan hanya disimpan sebagai state lokal browser.</p>
      </header>
      <Surface className="role-simulator-form">
        <TextField
          defaultValue="MSC September"
          id="simulator-program-title"
          label="Judul program"
        />
        <TextField
          defaultValue="Transformasi kebiasaan"
          id="simulator-program-category"
          label="Kategori"
        />
        <AppButton onClick={() => setSaved(true)}>Simpan draft simulasi</AppButton>
        {saved ? <p role="status">Draft simulasi tersimpan.</p> : null}
      </Surface>
      <AppLink href="/admin/program" variant="secondary">
        Kembali ke program
      </AppLink>
    </div>
  );
}

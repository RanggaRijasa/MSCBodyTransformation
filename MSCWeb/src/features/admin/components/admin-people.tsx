import type {
  AdminCoachApplication,
  AdminCorrectionTargets,
  AdminPerson,
} from "@/domain/admin/admin-operations";
import type { AdminProgramListItem } from "@/domain/admin/admin-program";
import {
  adjustScoreAction,
  correctWeighInAction,
  decideCoachApplicationAction,
  enrollParticipantAction,
  transferCoachAction,
} from "@/application/admin/admin-mutations";
import { AppButton, AppLink, StatusBadge, Surface } from "@/shared/ui";

const roleLabels = { admin: "Admin", coach: "Coach", participant: "Peserta" } as const;

export function AdminPeople({
  applications,
  correctionTargets,
  operationPeople,
  people,
  programs,
  role,
  search,
}: Readonly<{
  applications: readonly AdminCoachApplication[];
  correctionTargets: AdminCorrectionTargets;
  operationPeople: readonly AdminPerson[];
  people: readonly AdminPerson[];
  programs: readonly AdminProgramListItem[];
  role: string;
  search: string;
}>) {
  const participants = operationPeople.filter((person) => person.role === "participant");
  const coaches = operationPeople.filter((person) => person.role === "coach");
  return (
    <div className="admin-page">
      <header className="admin-page__header">
        <p className="admin-eyebrow">Direktori dan kewenangan</p>
        <h1>Orang</h1>
        <p>
          Peran berasal dari data server; halaman ini tidak menyediakan pintasan edit metadata
          peran.
        </p>
      </header>
      <Surface className="admin-filter-bar">
        <form action="/admin/orang" method="get">
          <label>
            Cari nama
            <input defaultValue={search} name="q" type="search" />
          </label>
          <label>
            Peran
            <select defaultValue={role} name="peran">
              <option value="">Semua peran</option>
              <option value="participant">Peserta</option>
              <option value="coach">Coach</option>
              <option value="admin">Admin</option>
            </select>
          </label>
          <AppButton type="submit">Terapkan</AppButton>
          <AppLink href="/admin/orang" variant="secondary">
            Hapus filter
          </AppLink>
        </form>
      </Surface>
      <div className="admin-people-layout">
        <section>
          <h2>Direktori</h2>
          <div className="admin-person-list">
            {people.map((person) => (
              <Surface className="admin-person-card" key={person.id}>
                <div>
                  <StatusBadge tone={person.role === "admin" ? "warning" : "neutral"}>
                    {roleLabels[person.role]}
                  </StatusBadge>
                  <h3>{person.displayName}</h3>
                  <p>{person.email}</p>
                  <p>{person.memberLevel ?? "Level belum tersedia"}</p>
                </div>
                {person.role === "admin" ? (
                  <p className="admin-restriction">
                    Akun Admin hanya dapat dikelola melalui operasi identitas terlindungi.
                  </p>
                ) : null}
              </Surface>
            ))}
          </div>
        </section>
        <section id="pengajuan">
          <h2>Pengajuan Coach</h2>
          <div className="admin-application-list">
            {applications.map((application) => (
              <Surface key={application.id}>
                <StatusBadge tone={application.status === "submitted" ? "warning" : "neutral"}>
                  {application.status}
                </StatusBadge>
                <h3>{application.displayName}</h3>
                <p>
                  {application.memberLevel} • HOM/STS{" "}
                  {application.hasCompletedHomSts ? "lengkap" : "belum"} • ICT{" "}
                  {application.hasCompletedIct ? "lengkap" : "belum"}
                </p>
                <p>Status pembayaran: {application.paymentStatus ?? "belum ada"}</p>
                {application.status === "submitted" ? (
                  <form action={decideCoachApplicationAction} className="admin-decision-form">
                    <input name="applicationId" type="hidden" value={application.id} />
                    <label>
                      Alasan keputusan
                      <textarea name="reason" />
                    </label>
                    <div>
                      <AppButton name="decision" type="submit" value="approved">
                        Terima kelayakan
                      </AppButton>
                      <AppButton
                        name="decision"
                        type="submit"
                        value="rejected"
                        variant="destructive"
                      >
                        Tolak
                      </AppButton>
                    </div>
                  </form>
                ) : null}
              </Surface>
            ))}
          </div>
        </section>
      </div>
      <details className="admin-operations">
        <summary>Operasi koreksi terkontrol</summary>
        <p>
          Gunakan identifier dari detail operasional terverifikasi. Semua alasan dicatat dalam
          audit; guard kapasitas, pembayaran, dan eligibility tetap berlaku.
        </p>
        <div className="admin-operation-forms">
          <form action={enrollParticipantAction}>
            <h3>Enrollment manual</h3>
            <label>
              Peserta
              <select name="participantId" required>
                <option value="">Pilih peserta</option>
                {participants.map((person) => (
                  <option key={person.id} value={person.id}>
                    {person.displayName}
                  </option>
                ))}
              </select>
            </label>
            <label>
              Program
              <select name="programId" required>
                <option value="">Pilih program</option>
                {programs
                  .filter((program) => ["active", "scheduled"].includes(program.status))
                  .map((program) => (
                    <option key={program.id} value={program.id}>
                      {program.title}
                    </option>
                  ))}
              </select>
            </label>
            <textarea name="reason" placeholder="Alasan override batas pendaftaran" required />
            <AppButton type="submit">Enroll peserta</AppButton>
          </form>
          <form action={transferCoachAction}>
            <h3>Pindahkan Coach</h3>
            <label>
              Peserta
              <select name="participantId" required>
                <option value="">Pilih peserta</option>
                {participants.map((person) => (
                  <option key={person.id} value={person.id}>
                    {person.displayName}
                  </option>
                ))}
              </select>
            </label>
            <label>
              Coach tujuan
              <select name="coachId" required>
                <option value="">Pilih Coach</option>
                {coaches.map((person) => (
                  <option key={person.id} value={person.id}>
                    {person.displayName}
                  </option>
                ))}
              </select>
            </label>
            <textarea name="reason" placeholder="Alasan pemindahan" required />
            <AppButton type="submit">Pindahkan Coach</AppButton>
          </form>
          <form action={correctWeighInAction}>
            <h3>Koreksi timbang</h3>
            <label>
              Catatan timbang
              <select name="weighInId" required>
                <option value="">Pilih catatan timbang</option>
                {correctionTargets.weighIns.map((item) => (
                  <option key={item.id} value={item.id}>
                    {item.label}
                  </option>
                ))}
              </select>
            </label>
            <input
              max="400"
              min="20"
              name="weight"
              placeholder="Berat (kg)"
              required
              step="0.01"
              type="number"
            />
            <textarea name="reason" placeholder="Alasan koreksi" required />
            <AppButton type="submit">Koreksi timbang</AppButton>
          </form>
          <form action={adjustScoreAction}>
            <h3>Penyesuaian poin</h3>
            <label>
              Enrollment
              <select name="enrollmentId" required>
                <option value="">Pilih enrollment</option>
                {correctionTargets.enrollments.map((item) => (
                  <option key={item.id} value={item.id}>
                    {item.label}
                  </option>
                ))}
              </select>
            </label>
            <input name="points" placeholder="Poin +/-" required type="number" />
            <textarea name="reason" placeholder="Alasan penyesuaian" required />
            <AppButton type="submit">Sesuaikan poin</AppButton>
          </form>
        </div>
      </details>
    </div>
  );
}

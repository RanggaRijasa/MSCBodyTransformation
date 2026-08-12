import Link from "next/link";

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
import {
  adminMemberLevelLabel,
  coachApplicationStatusLabel,
  paymentStatusLabel,
} from "@/features/admin/components/admin-presentation-labels";
import { AppButton, AppLink } from "@/shared/ui/controls/actions";
import { StateMessage, StatusBadge } from "@/shared/ui/status/status";
import { Surface } from "@/shared/ui/surfaces/surfaces";

const roleLabels = { admin: "Admin", coach: "Coach", participant: "Peserta" } as const;
const roleFilters = [
  { label: "Semua", value: "" },
  { label: "Peserta", value: "participant" },
  { label: "Coach", value: "coach" },
  { label: "Admin", value: "admin" },
] as const;

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
  const roleHref = (value: string) => {
    const values = new URLSearchParams();
    if (search) values.set("q", search);
    if (value) values.set("peran", value);
    const query = values.toString();
    return query ? `/admin/orang?${query}` : "/admin/orang";
  };
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
        <nav aria-label="Filter peran" className="admin-role-segments">
          {roleFilters.map((filter) => (
            <Link
              aria-current={role === filter.value ? "page" : undefined}
              href={roleHref(filter.value)}
              key={filter.value || "all"}
            >
              {filter.label}
            </Link>
          ))}
        </nav>
        <form action="/admin/orang" method="get">
          <label>
            Cari nama
            <input defaultValue={search} name="q" type="search" />
          </label>
          {role ? <input name="peran" type="hidden" value={role} /> : null}
          <AppButton type="submit">Terapkan</AppButton>
          <AppLink href="/admin/orang" variant="secondary">
            Hapus filter
          </AppLink>
        </form>
      </Surface>
      <div className="admin-people-layout">
        <section aria-labelledby="admin-directory-title">
          <div className="admin-section-intro">
            <div>
              <h2 id="admin-directory-title">Direktori</h2>
              <p>Akun dan peran yang dapat diakses oleh operasi Admin.</p>
            </div>
            <strong className="admin-result-count monospaced-numeric">{people.length}</strong>
          </div>
          <div className="admin-person-list">
            {people.length ? (
              people.map((person) => (
                <Surface className="admin-person-card" key={person.id}>
                  <div>
                    <StatusBadge tone={person.role === "admin" ? "warning" : "neutral"}>
                      {roleLabels[person.role]}
                    </StatusBadge>
                    <h3>{person.displayName}</h3>
                    <p>{person.email}</p>
                    <p>{adminMemberLevelLabel(person.memberLevel)}</p>
                  </div>
                  {person.role === "admin" ? (
                    <p className="admin-restriction">
                      Akun Admin hanya dapat dikelola melalui operasi identitas terlindungi.
                    </p>
                  ) : null}
                </Surface>
              ))
            ) : (
              <StateMessage
                description="Ubah kata pencarian atau filter peran untuk melihat hasil lain."
                title="Tidak ada orang yang cocok"
              />
            )}
          </div>
        </section>
        <section aria-labelledby="admin-applications-title" id="pengajuan">
          <div className="admin-section-intro">
            <div>
              <h2 id="admin-applications-title">Pengajuan Coach</h2>
              <p>Pembayaran dan keputusan kelayakan tetap diperiksa secara terpisah.</p>
            </div>
            <strong className="admin-result-count monospaced-numeric">{applications.length}</strong>
          </div>
          <div className="admin-application-list">
            {applications.length ? (
              applications.map((application) => (
                <Surface key={application.id}>
                  <StatusBadge tone={application.status === "submitted" ? "warning" : "neutral"}>
                    {coachApplicationStatusLabel(application.status)}
                  </StatusBadge>
                  <h3>{application.displayName}</h3>
                  <p>
                    {adminMemberLevelLabel(application.memberLevel)} • HOM/STS{" "}
                    {application.hasCompletedHomSts ? "lengkap" : "belum"} • ICT{" "}
                    {application.hasCompletedIct ? "lengkap" : "belum"}
                  </p>
                  <p>Status pembayaran: {paymentStatusLabel(application.paymentStatus)}</p>
                  {application.status === "submitted" ? (
                    <form action={decideCoachApplicationAction} className="admin-decision-form">
                      <input name="applicationId" type="hidden" value={application.id} />
                      <label>
                        Alasan keputusan
                        <textarea name="reason" required />
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
              ))
            ) : (
              <StateMessage
                description="Pengajuan baru akan muncul setelah peserta menyelesaikan proses aplikasi."
                title="Belum ada pengajuan Coach"
              />
            )}
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
            <label>
              Alasan melewati batas pendaftaran
              <textarea name="reason" required />
            </label>
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
            <label>
              Alasan pemindahan
              <textarea name="reason" required />
            </label>
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
            <label>
              Berat badan yang dikoreksi (kg)
              <input max="400" min="20" name="weight" required step="0.01" type="number" />
            </label>
            <label>
              Alasan koreksi timbang
              <textarea name="reason" required />
            </label>
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
            <label>
              Perubahan poin
              <input name="points" required type="number" />
            </label>
            <label>
              Alasan penyesuaian poin
              <textarea name="reason" required />
            </label>
            <AppButton type="submit">Sesuaikan poin</AppButton>
          </form>
        </div>
      </details>
    </div>
  );
}

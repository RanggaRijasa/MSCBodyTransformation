import type { AdminProgramDraft } from "@/domain/admin/admin-program";
import { projectDraftForPreview, validateProgramDraft } from "@/domain/admin/admin-program";
import {
  archiveProgramAction,
  completeProgramAction,
  duplicateProgramAction,
  lockWinnersAction,
  publishProgramAction,
  reopenProgramAction,
  reopenQuizAttemptAction,
} from "@/application/admin/admin-mutations";
import type { AdminProgramClosure } from "@/domain/admin/admin-operations";
import { adminProgramStatusLabels } from "@/features/admin/components/admin-presentation-labels";
import { ProgramContentPreview } from "@/shared/ui/program/program-content-preview";
import { AppButton, AppLink } from "@/shared/ui/controls/actions";
import { StatusBadge } from "@/shared/ui/status/status";
import { Surface } from "@/shared/ui/surfaces/surfaces";

export function AdminProgramDetail({
  closure,
  draft,
}: Readonly<{ closure: AdminProgramClosure; draft: AdminProgramDraft }>) {
  const issues = validateProgramDraft(draft);
  const preview = projectDraftForPreview(draft);
  const readOnly = draft.status !== "draft";
  return (
    <div className="admin-page">
      <header className="admin-page__header admin-page__header--action">
        <div>
          <p className="admin-eyebrow">Program {adminProgramStatusLabels[draft.status]}</p>
          <h1>{draft.title}</h1>
          <p>{draft.summary || "Belum ada ringkasan."}</p>
        </div>
        {readOnly ? (
          <StatusBadge tone="info">Proyeksi hanya baca</StatusBadge>
        ) : (
          <AppLink href={`/admin/program/${draft.id}/edit`}>Edit draft</AppLink>
        )}
      </header>
      <div className="admin-detail-layout">
        <div className="admin-detail-main">
          <Surface>
            <h2>Ringkasan validasi</h2>
            {issues.length ? (
              <ul className="admin-validation-list">
                {issues.map((issue) => (
                  <li key={`${issue.field}-${issue.message}`}>{issue.message}</li>
                ))}
              </ul>
            ) : (
              <p>Draft memenuhi validasi publikasi yang tersedia di client.</p>
            )}
          </Surface>
          <section className="admin-preview">
            <div className="admin-preview__heading">
              <div>
                <p className="admin-eyebrow">Penyaji bersama</p>
                <h2>Pratinjau Peserta dan Coach</h2>
              </div>
              <div role="group" aria-label="Audiens pratinjau">
                <span>Peserta</span>
                <span>Coach</span>
              </div>
            </div>
            {preview.days.map((day) => (
              <Surface key={day.id}>
                <h3>
                  Hari {day.dayNumber}: {day.title}
                </h3>
                {day.steps.map((step) => (
                  <div className="admin-step-preview" key={step.id}>
                    <h4>{step.title}</h4>
                    <ProgramContentPreview audience="admin" step={step} />
                  </div>
                ))}
              </Surface>
            ))}
          </section>
        </div>
        <aside className="admin-operation-panel">
          {draft.status !== "draft" ? <ClosurePreflight closure={closure} /> : null}
          {draft.status === "draft" ? (
            <form action={publishProgramAction}>
              <input name="programId" type="hidden" value={draft.id} />
              <p>Publikasi mengunci editor dan menjalankan validasi server.</p>
              <AppButton disabled={issues.length > 0} type="submit">
                Terbitkan program
              </AppButton>
            </form>
          ) : null}
          <form action={duplicateProgramAction}>
            <input name="programId" type="hidden" value={draft.id} />
            <label>
              Judul salinan
              <input name="title" required />
            </label>
            <label>
              Tanggal mulai
              <input name="startsOn" required type="date" />
            </label>
            <AppButton type="submit" variant="secondary">
              Duplikasi sebagai draft
            </AppButton>
          </form>
          {["active", "scheduled"].includes(draft.status) ? (
            <form action={completeProgramAction}>
              <input name="programId" type="hidden" value={draft.id} />
              <label>
                Alasan penyelesaian
                <textarea name="reason" required />
              </label>
              <AppButton disabled={!closure.canComplete} type="submit" variant="destructive">
                Selesaikan program
              </AppButton>
            </form>
          ) : null}
          {draft.status === "completed" ? (
            <>
              {closure.canReopen ? (
                <form action={reopenProgramAction}>
                  <input name="programId" type="hidden" value={draft.id} />
                  <label>
                    Alasan buka kembali
                    <textarea name="reason" required />
                  </label>
                  <AppButton type="submit" variant="secondary">
                    Buka kembali program
                  </AppButton>
                </form>
              ) : null}
              <form action={lockWinnersAction}>
                <input name="programId" type="hidden" value={draft.id} />
                <p>Pastikan seluruh pemeriksaan dan timbang akhir selesai.</p>
                <AppButton disabled={!closure.canLock} type="submit">
                  Kunci pemenang
                </AppButton>
              </form>
              <form action={archiveProgramAction}>
                <input name="programId" type="hidden" value={draft.id} />
                <label>
                  Alasan arsip
                  <textarea name="reason" required />
                </label>
                <AppButton type="submit" variant="destructive">
                  Arsipkan program
                </AppButton>
              </form>
            </>
          ) : null}
        </aside>
      </div>
    </div>
  );
}

function ClosurePreflight({ closure }: Readonly<{ closure: AdminProgramClosure }>) {
  const blockerCount =
    closure.pendingReviews +
    closure.missingFinalWeights +
    closure.failedQuizAttempts +
    closure.incompleteEnrollments;
  return (
    <section aria-labelledby="closure-preflight-title" className="admin-closure-preflight">
      <div>
        <h2 id="closure-preflight-title">Prasyarat penutupan</h2>
        <StatusBadge tone={blockerCount === 0 ? "success" : "warning"}>
          {blockerCount === 0 ? "Siap ditutup" : `${blockerCount} hambatan`}
        </StatusBadge>
      </div>
      <dl>
        <div>
          <dt>Menunggu pemeriksaan</dt>
          <dd>{closure.pendingReviews}</dd>
        </div>
        <div>
          <dt>Berat akhir belum ada</dt>
          <dd>{closure.missingFinalWeights}</dd>
        </div>
        <div>
          <dt>Kuis belum lulus</dt>
          <dd>{closure.failedQuizAttempts}</dd>
        </div>
        <div>
          <dt>Enrollment belum lengkap</dt>
          <dd>{closure.incompleteEnrollments}</dd>
        </div>
      </dl>
      {closure.failedQuizzes.map((quiz) => (
        <form action={reopenQuizAttemptAction} key={`${quiz.enrollmentId}-${quiz.stepId}`}>
          <input name="enrollmentId" type="hidden" value={quiz.enrollmentId} />
          <input name="programId" type="hidden" value={closure.programId} />
          <input name="stepId" type="hidden" value={quiz.stepId} />
          <p>
            <strong>{quiz.participantDisplayName}</strong> · {quiz.stepTitle} · percobaan{" "}
            {quiz.attemptSequence} · {quiz.percentage}%
          </p>
          <label>
            Alasan membuka kuis
            <textarea name="reason" required />
          </label>
          <AppButton type="submit" variant="secondary">
            Buka percobaan baru
          </AppButton>
        </form>
      ))}
      {closure.winnerSnapshotId ? (
        <p>Snapshot pemenang sudah dikunci dan tidak dapat diubah.</p>
      ) : null}
    </section>
  );
}

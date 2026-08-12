import Image from "next/image";
import Link from "next/link";

import type { CoachParticipantDetail, CoachPrivateAnswer } from "@/domain/coach/coach-experience";
import {
  createProgramDateTimeFormatter,
  formatNumber,
  formatWeightKilograms,
} from "@/shared/formatting/indonesian-formatters";
import { Avatar, Progress, StatusBadge, Surface } from "@/shared/ui";

export function CoachParticipantDetailView({
  detail,
}: Readonly<{ detail: CoachParticipantDetail }>) {
  const formatter = createProgramDateTimeFormatter(detail.program.timezone);
  return (
    <div className="coach-participant-detail">
      <Link className="coach-back-link" href="/coach-area/peserta">
        Kembali ke Peserta saya
      </Link>
      <header className="coach-identity-header">
        <Avatar
          {...(detail.avatarUrl ? { imageUrl: detail.avatarUrl } : {})}
          name={detail.displayName}
          size={64}
        />
        <div>
          <p className="coach-eyebrow">Detail privat Peserta</p>
          <h1>{detail.displayName}</h1>
          <p>
            {detail.city ?? "Kota belum diisi"} · {detail.phoneNumber ?? "Nomor HP belum diisi"}
          </p>
        </div>
      </header>
      {detail.enrollments.length > 1 ? (
        <nav aria-label="Pilih riwayat program" className="coach-program-strip">
          {detail.enrollments.map((enrollment) => (
            <Link
              aria-current={enrollment.id === detail.enrollmentId ? "page" : undefined}
              className="coach-program-chip"
              href={`/coach-area/peserta/${detail.participantId}?program=${enrollment.programId}`}
              key={enrollment.id}
            >
              {enrollment.programTitle}
            </Link>
          ))}
        </nav>
      ) : null}
      <Surface className="coach-detail-summary">
        <div>
          <h2>{detail.program.title}</h2>
          <Progress
            label={`Progres ${detail.displayName}`}
            value={detail.score.progressPercentage}
          />
        </div>
        <dl>
          <div>
            <dt>Total</dt>
            <dd>{formatNumber.format(detail.score.totalPoints)} poin</dd>
          </div>
          <div>
            <dt>Aktivitas</dt>
            <dd>{formatNumber.format(detail.score.activityPoints)}</dd>
          </div>
          <div>
            <dt>Kuis</dt>
            <dd>{formatNumber.format(detail.score.quizPoints)}</dd>
          </div>
          <div>
            <dt>Berat</dt>
            <dd>{formatNumber.format(detail.score.weightPoints)}</dd>
          </div>
          <div>
            <dt>Penyesuaian</dt>
            <dd>{formatNumber.format(detail.score.adjustmentPoints)}</dd>
          </div>
        </dl>
      </Surface>
      <section aria-labelledby="coach-weight-history">
        <h2 id="coach-weight-history">Riwayat berat privat</h2>
        <p>Data kebugaran ini hanya untuk pendampingan, bukan diagnosis.</p>
        {detail.weighIns.length ? (
          <ol className="coach-weight-list">
            {detail.weighIns.map((weigh, index) => (
              <li key={`${weigh.recordedAt}-${index}`}>
                <strong>
                  {weigh.type === "initial"
                    ? "Berat awal"
                    : weigh.type === "final"
                      ? "Berat akhir"
                      : "Berat harian"}
                </strong>
                <span>{formatWeightKilograms.format(Number(weigh.weightKilograms))}</span>
                <time dateTime={weigh.recordedAt}>
                  {formatter.format(new Date(weigh.recordedAt))}
                </time>
              </li>
            ))}
          </ol>
        ) : (
          <p>Belum ada riwayat timbang.</p>
        )}
      </section>
      <section aria-labelledby="coach-step-history">
        <h2 id="coach-step-history">Langkah dan jawaban</h2>
        <div className="coach-submission-list">
          {detail.submissions.map((submission) => (
            <Surface key={submission.id}>
              <header>
                <div>
                  <h3>{submission.stepTitle}</h3>
                  <p>
                    Percobaan {formatNumber.format(submission.attemptSequence)}
                    {submission.submittedAt
                      ? ` · ${formatter.format(new Date(submission.submittedAt))}`
                      : ""}
                  </p>
                </div>
                <StatusBadge
                  tone={
                    submission.status === "approved"
                      ? "success"
                      : submission.status === "rejected"
                        ? "error"
                        : "warning"
                  }
                >
                  {submission.status === "approved"
                    ? "Disetujui"
                    : submission.status === "rejected"
                      ? "Ditolak"
                      : submission.status === "pending"
                        ? "Menunggu"
                        : "Draft"}
                </StatusBadge>
              </header>
              {submission.reviewNote ? <p>Catatan: {submission.reviewNote}</p> : null}
              {submission.answers.map((answer) => (
                <CoachAnswer answer={answer} key={answer.questionId} submissionId={submission.id} />
              ))}
            </Surface>
          ))}
          {!detail.submissions.length ? <p>Belum ada aktivitas yang dikirim.</p> : null}
        </div>
      </section>
    </div>
  );
}

export function CoachAnswer({
  answer,
  submissionId,
}: Readonly<{ answer: CoachPrivateAnswer; submissionId: string }>) {
  const selected =
    answer.question?.options
      .filter(({ id }) => answer.selectedOptionIds.includes(id))
      .map(({ title }) => title) ?? [];
  return (
    <div className="coach-answer">
      <strong>{answer.question?.prompt ?? "Jawaban Peserta"}</strong>
      {answer.textValue ? <p>{answer.textValue}</p> : null}
      {answer.numberValue ? <p>{answer.numberValue}</p> : null}
      {selected.length ? <p>{selected.join(", ")}</p> : null}
      {answer.answerKey ? (
        <div className="coach-answer-key">
          <strong>Kunci jawaban</strong>
          <p>
            {answer.answerKey.acceptedTextValues.join(", ") ||
              answer.answerKey.numberValue ||
              answer.question?.options
                .filter(({ id }) => answer.answerKey?.selectedOptionIds.includes(id))
                .map(({ title }) => title)
                .join(", ") ||
              "Kriteria jawaban tersedia pada server."}
          </p>
        </div>
      ) : null}
      {answer.hasPhoto ? (
        <Image
          alt={`Foto jawaban untuk ${answer.question?.prompt ?? "pertanyaan"}`}
          height={640}
          loading="lazy"
          src={`/api/coach/submissions/${submissionId}/photos/${answer.questionId}`}
          unoptimized
          width={960}
        />
      ) : null}
    </div>
  );
}

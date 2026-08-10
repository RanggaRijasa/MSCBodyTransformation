import type { PublicProgramStep } from "@/domain/programs/program";
import { MediaSurface } from "@/shared/ui/media/media-surface";
import { StatusBadge } from "@/shared/ui/status/status";
import { Surface } from "@/shared/ui/surfaces/surfaces";

const kindLabels = {
  heading: "Judul bagian",
  image_choice: "Pilihan gambar",
  long_answer: "Jawaban panjang",
  multiple_choice: "Pilihan ganda",
  number: "Angka",
  photo_upload: "Foto privat",
  short_answer: "Jawaban singkat",
  single_choice: "Pilihan tunggal",
  text: "Teks panduan",
} as const;

export function ProgramContentPreview({
  audience,
  showQuestions = true,
  step,
}: Readonly<{
  audience: "admin" | "coach" | "participant";
  showQuestions?: boolean;
  step: PublicProgramStep;
}>) {
  return (
    <div className="program-content-preview" data-audience={audience}>
      {step.instructions ? (
        <Surface className="program-content-preview__instructions">
          <p>{step.instructions}</p>
        </Surface>
      ) : null}
      {step.contentKind === "article" && step.mediaUrl ? (
        <MediaSurface alt={step.mediaAlternativeText || step.title} src={step.mediaUrl} />
      ) : null}
      {showQuestions ? (
        <div className="program-content-preview__questions">
          {step.questions.map((question) =>
            question.kind === "heading" ? (
              <h3 key={question.id}>{question.prompt}</h3>
            ) : question.kind === "text" ? (
              <p key={question.id}>{question.prompt}</p>
            ) : (
              <Surface className="program-content-preview__question" key={question.id}>
                <div>
                  <strong>{question.prompt}</strong>
                  <StatusBadge tone="neutral">{kindLabels[question.kind]}</StatusBadge>
                </div>
                {question.options.length ? (
                  <ul>
                    {question.options.map((option) => (
                      <li key={option.id}>{option.title}</li>
                    ))}
                  </ul>
                ) : null}
              </Surface>
            ),
          )}
        </div>
      ) : null}
    </div>
  );
}

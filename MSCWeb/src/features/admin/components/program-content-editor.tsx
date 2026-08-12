import type {
  AdminProgramDay,
  AdminProgramDraft,
  AdminProgramStep,
} from "@/domain/admin/admin-program";
import type { ProgramContentKind, ProgramQuestionKind } from "@/domain/programs/program";
import {
  programContentKindLabels,
  programQuestionKindLabels,
} from "@/features/admin/components/admin-presentation-labels";
import { AppButton } from "@/shared/ui/controls/actions";
import { SelectField, TextareaField, TextField } from "@/shared/ui/forms/form-controls";
import { Surface } from "@/shared/ui/surfaces/surfaces";

const contentKinds: readonly ProgramContentKind[] = [
  "article",
  "video",
  "form",
  "quiz",
  "initial_weigh_in",
  "daily_weigh_in",
  "final_weigh_in",
];
const questionKinds: readonly ProgramQuestionKind[] = [
  "heading",
  "text",
  "short_answer",
  "long_answer",
  "number",
  "single_choice",
  "multiple_choice",
  "image_choice",
  "photo_upload",
];

function makeStep(makeId: () => string, order: number): AdminProgramStep {
  return {
    completionPolicy: "mark_complete",
    contentKind: "article",
    id: makeId(),
    instructions: "",
    mediaAlternativeText: null,
    mediaPath: null,
    order,
    questions: [],
    title: `Langkah ${order}`,
    verificationMode: "automatic",
    videoAutoplay: false,
    videoRequired: false,
    videoThreshold: null,
  };
}

export function ProgramContentEditor({
  draft,
  makeId,
  onChange,
}: Readonly<{
  draft: AdminProgramDraft;
  makeId: () => string;
  onChange: (draft: AdminProgramDraft) => void;
}>) {
  const replaceDay = (day: AdminProgramDay) =>
    onChange({ ...draft, days: draft.days.map((item) => (item.id === day.id ? day : item)) });
  const addDay = () => {
    const number = draft.days.length + 1;
    const date = new Date(`${draft.startsOn}T12:00:00Z`);
    date.setUTCDate(date.getUTCDate() + number - 1);
    onChange({
      ...draft,
      days: [
        ...draft.days,
        {
          dayNumber: number,
          id: makeId(),
          scheduledOn: date.toISOString().slice(0, 10),
          steps: [],
          summary: null,
          title: `Hari ${number}`,
        },
      ],
    });
  };
  return (
    <div className="admin-day-editor">
      {draft.days.map((day) => (
        <Surface className="admin-day-card" key={day.id}>
          <header>
            <div>
              <span>Hari {day.dayNumber}</span>
              <h3>{day.title}</h3>
            </div>
            <AppButton
              disabled={draft.days.length === 1}
              onClick={() =>
                onChange({
                  ...draft,
                  days: draft.days
                    .filter((item) => item.id !== day.id)
                    .map((item, index) => ({ ...item, dayNumber: index + 1 })),
                })
              }
              variant="destructive"
            >
              Hapus hari
            </AppButton>
          </header>
          <div className="admin-editor-grid">
            <TextField
              id={`day-title-${day.id}`}
              label="Judul hari"
              onChange={(event) => replaceDay({ ...day, title: event.target.value })}
              value={day.title}
            />
            <TextField
              id={`day-date-${day.id}`}
              label="Tanggal"
              onChange={(event) => replaceDay({ ...day, scheduledOn: event.target.value })}
              type="date"
              value={day.scheduledOn}
            />
            <TextareaField
              id={`day-summary-${day.id}`}
              label="Ringkasan hari"
              onChange={(event) => replaceDay({ ...day, summary: event.target.value || null })}
              value={day.summary ?? ""}
            />
          </div>
          <div className="admin-step-editor">
            {day.steps.map((step) => (
              <Surface className="admin-step-card" key={step.id}>
                <div className="admin-editor-grid">
                  <TextField
                    id={`step-title-${step.id}`}
                    label="Judul langkah"
                    onChange={(event) =>
                      replaceDay({
                        ...day,
                        steps: day.steps.map((item) =>
                          item.id === step.id ? { ...step, title: event.target.value } : item,
                        ),
                      })
                    }
                    value={step.title}
                  />
                  <SelectField
                    id={`step-kind-${step.id}`}
                    label="Jenis konten"
                    onChange={(event) =>
                      replaceDay({
                        ...day,
                        steps: day.steps.map((item) =>
                          item.id === step.id
                            ? { ...step, contentKind: event.target.value as ProgramContentKind }
                            : item,
                        ),
                      })
                    }
                    value={step.contentKind}
                  >
                    {contentKinds.map((kind) => (
                      <option key={kind} value={kind}>
                        {programContentKindLabels[kind]}
                      </option>
                    ))}
                  </SelectField>
                  <TextareaField
                    id={`step-instructions-${step.id}`}
                    label="Petunjuk"
                    onChange={(event) =>
                      replaceDay({
                        ...day,
                        steps: day.steps.map((item) =>
                          item.id === step.id
                            ? { ...step, instructions: event.target.value }
                            : item,
                        ),
                      })
                    }
                    value={step.instructions}
                  />
                </div>
                <div className="admin-question-list">
                  {step.questions.map((question) => (
                    <div className="admin-question-row" key={question.id}>
                      <SelectField
                        id={`question-kind-${question.id}`}
                        label="Jenis pertanyaan"
                        onChange={(event) =>
                          replaceDay({
                            ...day,
                            steps: day.steps.map((item) =>
                              item.id === step.id
                                ? {
                                    ...step,
                                    questions: step.questions.map((entry) =>
                                      entry.id === question.id
                                        ? {
                                            ...question,
                                            kind: event.target.value as ProgramQuestionKind,
                                          }
                                        : entry,
                                    ),
                                  }
                                : item,
                            ),
                          })
                        }
                        value={question.kind}
                      >
                        {questionKinds.map((kind) => (
                          <option key={kind} value={kind}>
                            {programQuestionKindLabels[kind]}
                          </option>
                        ))}
                      </SelectField>
                      <TextField
                        id={`question-prompt-${question.id}`}
                        label="Isi"
                        onChange={(event) =>
                          replaceDay({
                            ...day,
                            steps: day.steps.map((item) =>
                              item.id === step.id
                                ? {
                                    ...step,
                                    questions: step.questions.map((entry) =>
                                      entry.id === question.id
                                        ? { ...question, prompt: event.target.value }
                                        : entry,
                                    ),
                                  }
                                : item,
                            ),
                          })
                        }
                        value={question.prompt}
                      />
                    </div>
                  ))}
                </div>
                <div className="admin-inline-actions">
                  <AppButton
                    onClick={() =>
                      replaceDay({
                        ...day,
                        steps: day.steps.map((item) =>
                          item.id === step.id
                            ? {
                                ...step,
                                questions: [
                                  ...step.questions,
                                  {
                                    answerKey:
                                      step.contentKind === "quiz"
                                        ? {
                                            acceptedTextValues: [],
                                            matchingMode: "exact",
                                            numberValue: null,
                                            selectedOptionIds: [],
                                          }
                                        : null,
                                    id: makeId(),
                                    kind: "short_answer",
                                    options: [],
                                    order: step.questions.length + 1,
                                    prompt: "",
                                  },
                                ],
                              }
                            : item,
                        ),
                      })
                    }
                    variant="secondary"
                  >
                    Tambah pertanyaan
                  </AppButton>
                  <AppButton
                    onClick={() =>
                      replaceDay({
                        ...day,
                        steps: day.steps
                          .filter((item) => item.id !== step.id)
                          .map((item, index) => ({ ...item, order: index + 1 })),
                      })
                    }
                    variant="destructive"
                  >
                    Hapus langkah
                  </AppButton>
                </div>
              </Surface>
            ))}
          </div>
          <AppButton
            onClick={() =>
              replaceDay({ ...day, steps: [...day.steps, makeStep(makeId, day.steps.length + 1)] })
            }
            variant="secondary"
          >
            Tambah langkah
          </AppButton>
        </Surface>
      ))}
      <AppButton onClick={addDay}>Tambah hari</AppButton>
    </div>
  );
}

"use client";

import { useId } from "react";

import type { PublicProgramQuestion } from "@/domain/programs/program";
import { ImageAcquisition } from "@/features/device-media";
import type {
  ParticipantAnswerDraft,
  ParticipantAnswerDrafts,
} from "@/features/participant/model/participant-answer-state";
import { ChoiceField, TextareaField, TextField } from "@/shared/ui/forms/form-controls";
import { MediaSurface } from "@/shared/ui/media/media-surface";

type QuestionFieldsProperties = Readonly<{
  drafts: ParticipantAnswerDrafts;
  errors: Readonly<Record<string, string>>;
  onChange: (questionId: string, draft: ParticipantAnswerDraft) => void;
  questions: readonly PublicProgramQuestion[];
}>;

export function ProgramQuestionFields({
  drafts,
  errors,
  onChange,
  questions,
}: QuestionFieldsProperties) {
  const groupInstanceId = useId();
  return (
    <div className="participant-question-list">
      {questions.map((question) => {
        const draft = drafts[question.id] ?? { selectedOptionIds: [], value: "" };
        if (question.kind === "heading") return <h2 key={question.id}>{question.prompt}</h2>;
        if (question.kind === "text")
          return (
            <p className="participant-content-text" key={question.id}>
              {question.prompt}
            </p>
          );
        if (question.kind === "short_answer")
          return (
            <TextField
              {...(errors[question.id] ? { error: errors[question.id] } : {})}
              id={`question-${question.id}`}
              key={question.id}
              label={question.prompt}
              onChange={(event) => onChange(question.id, { ...draft, value: event.target.value })}
              value={draft.value}
            />
          );
        if (question.kind === "long_answer")
          return (
            <TextareaField
              {...(errors[question.id] ? { error: errors[question.id] } : {})}
              id={`question-${question.id}`}
              key={question.id}
              label={question.prompt}
              onChange={(event) => onChange(question.id, { ...draft, value: event.target.value })}
              rows={5}
              value={draft.value}
            />
          );
        if (question.kind === "number")
          return (
            <TextField
              description="Gunakan koma atau titik untuk desimal, maksimal dua angka desimal."
              {...(errors[question.id] ? { error: errors[question.id] } : {})}
              id={`question-${question.id}`}
              inputMode="decimal"
              key={question.id}
              label={question.prompt}
              onChange={(event) => onChange(question.id, { ...draft, value: event.target.value })}
              value={draft.value}
            />
          );
        if (question.kind === "photo_upload")
          return (
            <fieldset className="participant-question" key={question.id}>
              <legend>{question.prompt}</legend>
              <ImageAcquisition
                label={question.prompt}
                onProcessed={(photo) => onChange(question.id, { ...draft, photo })}
              />
              {errors[question.id] ? (
                <p className="form-field__error" role="alert">
                  {errors[question.id]}
                </p>
              ) : null}
            </fieldset>
          );
        const isMultiple = question.kind === "multiple_choice";
        return (
          <fieldset className="participant-question" key={question.id}>
            <legend>{question.prompt}</legend>
            <div
              className={
                question.kind === "image_choice"
                  ? "participant-option-grid"
                  : "participant-choice-list"
              }
            >
              {question.options.map((option) => {
                const checked = draft.selectedOptionIds.includes(option.id);
                return (
                  <div className="participant-choice" key={option.id}>
                    {question.kind === "image_choice" ? (
                      <MediaSurface
                        alt={option.mediaAlternativeText || option.title}
                        {...(option.mediaUrl ? { src: option.mediaUrl } : {})}
                        aspect="square"
                      />
                    ) : null}
                    <ChoiceField
                      checked={checked}
                      id={`question-${question.id}-option-${option.id}`}
                      label={option.title}
                      name={`${groupInstanceId}-question-${question.id}`}
                      onChange={() => {
                        const selectedOptionIds = isMultiple
                          ? checked
                            ? draft.selectedOptionIds.filter((id) => id !== option.id)
                            : [...draft.selectedOptionIds, option.id]
                          : [option.id];
                        onChange(question.id, { ...draft, selectedOptionIds });
                      }}
                      type={isMultiple ? "checkbox" : "radio"}
                    />
                  </div>
                );
              })}
            </div>
            {errors[question.id] ? (
              <p className="form-field__error" role="alert">
                {errors[question.id]}
              </p>
            ) : null}
          </fieldset>
        );
      })}
    </div>
  );
}

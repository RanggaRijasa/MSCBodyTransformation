const uuidPattern = /^[0-9a-f]{8}-[0-9a-f]{4}-[1-5][0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$/i;
const decimalPattern = /^-?\d{1,12}(?:\.\d{1,6})?$/;
const privatePhotoPathPattern = new RegExp(
  `^(?:${uuidPattern.source.slice(1, -1)}/){4}${uuidPattern.source.slice(1, -1)}\\.jpg$`,
  "i",
);

const maximumAnswerCount = 100;
const maximumTextLength = 10_000;
const maximumSelectedOptionCount = 100;

export type ParticipantAnswerInput = Readonly<{
  numberValue?: string;
  privatePhotoPath?: string;
  questionId: string;
  selectedOptionIds?: readonly string[];
  textValue?: string;
}>;

function optionalString(
  record: Readonly<Record<string, unknown>>,
  key: keyof ParticipantAnswerInput,
  isValid: (value: string) => boolean,
) {
  const value = record[key];
  if (value === undefined) return { isValid: true as const, value: undefined };
  return typeof value === "string" && isValid(value)
    ? { isValid: true as const, value }
    : { isValid: false as const, value: undefined };
}

export function parseParticipantAnswers(input: unknown): readonly ParticipantAnswerInput[] | null {
  if (!Array.isArray(input) || input.length > maximumAnswerCount) return null;
  const answers: ParticipantAnswerInput[] = [];
  const seenQuestions = new Set<string>();

  for (const candidate of input) {
    if (!candidate || typeof candidate !== "object" || Array.isArray(candidate)) return null;
    const record = candidate as Readonly<Record<string, unknown>>;
    const questionId = record.questionId;
    if (
      typeof questionId !== "string" ||
      !uuidPattern.test(questionId) ||
      seenQuestions.has(questionId)
    )
      return null;

    const text = optionalString(record, "textValue", (value) => value.length <= maximumTextLength);
    const number = optionalString(record, "numberValue", (value) => decimalPattern.test(value));
    const photo = optionalString(record, "privatePhotoPath", (value) =>
      privatePhotoPathPattern.test(value),
    );
    if (!text.isValid || !number.isValid || !photo.isValid) return null;

    const selected = record.selectedOptionIds;
    if (
      selected !== undefined &&
      (!Array.isArray(selected) ||
        selected.length > maximumSelectedOptionCount ||
        selected.some((value) => typeof value !== "string" || !uuidPattern.test(value)) ||
        new Set(selected).size !== selected.length)
    ) {
      return null;
    }

    seenQuestions.add(questionId);
    answers.push({
      ...(number.value === undefined ? {} : { numberValue: number.value }),
      ...(photo.value === undefined ? {} : { privatePhotoPath: photo.value }),
      questionId,
      ...(selected === undefined ? {} : { selectedOptionIds: selected as string[] }),
      ...(text.value === undefined ? {} : { textValue: text.value }),
    });
  }
  return answers;
}

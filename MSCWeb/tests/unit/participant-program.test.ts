import { describe, expect, it } from "vitest";

import type { ParticipantProgram } from "@/domain/participant/participant-program";
import { parseParticipantAnswers } from "@/domain/participant/participant-answer-input";
import type { PublicProgram, PublicProgramStep } from "@/domain/programs/program";
import {
  canonicalIndonesianWeight,
  focusedParticipantDay,
  latestSubmission,
  presentParticipantStep,
  selectParticipantProgram,
} from "@/domain/services/participant-program";

function program(id = "program-1"): PublicProgram {
  return {
    category: "Transformasi",
    coverAlternativeText: null,
    coverImageUrl: null,
    days: [],
    desiredPrice: null,
    endsOn: "2026-08-31",
    futureStepPolicy: "locked",
    id,
    participantLimit: null,
    pastStepPolicy: "read_only",
    pointsPerActivity: 10,
    pointsPerWeightKilogram: "100.00",
    pricingMode: "free",
    quizPassingPercentage: 70,
    registrationClosesAt: null,
    startsOn: "2026-08-01",
    status: "active",
    summary: "Program sehat.",
    timezone: "Asia/Makassar",
    title: id,
    wellnessDisclaimer: "Bukan layanan diagnosis.",
  };
}

function step(): PublicProgramStep {
  return {
    completionPolicy: "answer_all_questions",
    contentKind: "form",
    id: "step-1",
    instructions: "Jawab dengan jujur.",
    mediaAlternativeText: null,
    mediaPath: null,
    mediaUrl: null,
    order: 1,
    questions: [],
    title: "Refleksi",
    verificationMode: "coach_review",
    videoAutoplay: false,
    videoRequired: false,
    videoThreshold: null,
  };
}

function participantProgram(id = "program-1"): ParticipantProgram {
  return {
    access: [
      {
        accessState: "available",
        dayNumber: 1,
        enrollmentId: `enrollment-${id}`,
        isCurrentDay: true,
        programDayId: "day-1",
        programId: id,
      },
    ],
    enrollmentId: `enrollment-${id}`,
    enrollmentStatus: "active",
    program: program(id),
    quizResults: [],
    score: {
      activityPoints: 0,
      adjustmentPoints: 0,
      progressPercentage: 0,
      quizPoints: 0,
      rank: null,
      totalPoints: 0,
      weightPoints: 0,
    },
    submissions: [],
    weighedStepIds: [],
  };
}

describe("domain pengalaman Peserta", () => {
  it("menerima payload jawaban typed dan menolak bentuk yang tidak aman", () => {
    const questionId = "00000000-0000-4000-8000-000000000101";
    const optionId = "00000000-0000-4000-8000-000000000102";
    const photoPath = [
      "00000000-0000-4000-8000-000000000103",
      "00000000-0000-4000-8000-000000000104",
      "00000000-0000-4000-8000-000000000105",
      questionId,
      "00000000-0000-4000-8000-000000000106.jpg",
    ].join("/");

    expect(
      parseParticipantAnswers([
        {
          numberValue: "72.5",
          privatePhotoPath: photoPath,
          questionId,
          selectedOptionIds: [optionId],
        },
      ]),
    ).not.toBeNull();
    expect(
      parseParticipantAnswers([{ questionId: "bukan-uuid", textValue: "jawaban" }]),
    ).toBeNull();
    expect(parseParticipantAnswers([{ numberValue: "7e2", questionId }])).toBeNull();
    expect(parseParticipantAnswers([{ privatePhotoPath: "../foto.jpg", questionId }])).toBeNull();
    expect(
      parseParticipantAnswers([{ questionId, selectedOptionIds: [optionId, optionId] }]),
    ).toBeNull();
  });

  it.each([
    ["72,35", "72.35"],
    ["72.50", "72.5"],
    ["20", "20"],
    ["400,00", "400"],
  ])("mem-parsing berat locale id-ID tanpa otoritas binary float", (input, expected) => {
    expect(canonicalIndonesianWeight(input)).toEqual({ isSuccess: true, value: expected });
  });

  it.each(["19,99", "400,01", "72,345", "NaN", "72,3,1"])("menolak berat tidak valid %s", (input) =>
    expect(canonicalIndonesianWeight(input).isSuccess).toBe(false),
  );

  it("memilih attempt terbaru dan memetakan lifecycle tanpa klaim lokal", () => {
    const target = participantProgram();
    const submissions = [
      {
        attemptSequence: 1,
        id: "submission-1",
        reviewNote: "Foto kurang jelas",
        status: "rejected" as const,
        stepId: "step-1",
        submittedAt: "2026-08-10T00:00:00Z",
      },
      {
        attemptSequence: 2,
        id: "submission-2",
        reviewNote: null,
        status: "pending" as const,
        stepId: "step-1",
        submittedAt: "2026-08-10T01:00:00Z",
      },
    ];
    expect(latestSubmission(submissions, "step-1")?.id).toBe("submission-2");
    expect(presentParticipantStep(step(), "available", { ...target, submissions }).status).toBe(
      "pending",
    );
    expect(presentParticipantStep(step(), "locked", target).href).toBeNull();
    expect(presentParticipantStep(step(), "read_only", target).status).toBe("read_only");
  });

  it("memakai satu hasil hari server dan menjaga pilihan antarprogram terisolasi", () => {
    const first = participantProgram("program-a");
    const second = {
      ...participantProgram("program-b"),
      access: [{ ...participantProgram("program-b").access[0]!, isCurrentDay: false }],
    };
    expect(focusedParticipantDay(first)?.programDayId).toBe("day-1");
    expect(selectParticipantProgram([first, second], "program-b")?.program.id).toBe("program-b");
    expect(selectParticipantProgram([first, second], "unknown")?.program.id).toBe("program-a");
  });
});

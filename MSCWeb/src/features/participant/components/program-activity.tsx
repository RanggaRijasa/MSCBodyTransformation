import type { ParticipantProgram } from "@/domain/participant/participant-program";
import {
  focusedParticipantDay,
  presentParticipantStep,
} from "@/domain/services/participant-program";
import { formatProgramDate, programTimezoneLabel } from "@/shared/formatting/indonesian-formatters";
import {
  ProgramActivityRenderer,
  type ProgramActivityModel,
} from "@/shared/ui/program/program-activity-renderer";
import type { StatusTone } from "@/shared/ui/status/status";

const tones: Readonly<Record<ReturnType<typeof presentParticipantStep>["status"], StatusTone>> = {
  approved: "success",
  available: "info",
  locked: "neutral",
  pending: "warning",
  read_only: "neutral",
  rejected: "error",
};

const labels: Readonly<Record<ReturnType<typeof presentParticipantStep>["status"], string>> = {
  approved: "Selesai",
  available: "Tersedia",
  locked: "Terkunci",
  pending: "Menunggu",
  read_only: "Riwayat",
  rejected: "Perlu perbaikan",
};

export function ProgramActivity({
  participantProgram,
}: Readonly<{ participantProgram: ParticipantProgram }>) {
  const focus = focusedParticipantDay(participantProgram);
  const accessByDay = new Map(participantProgram.access.map((item) => [item.programDayId, item]));
  const model: ProgramActivityModel = {
    days: participantProgram.program.days.flatMap((day) => {
      const access = accessByDay.get(day.id);
      if (!access || access.accessState === "hidden") return [];
      return [
        {
          id: day.id,
          isFocused: day.id === focus?.programDayId,
          label: `${access.isCurrentDay ? "Hari ini" : `Hari ${day.dayNumber}`} · ${day.title}`,
          steps: day.steps.map((step) => {
            const presentation = presentParticipantStep(
              step,
              access.accessState,
              participantProgram,
            );
            return {
              detail: presentation.detail,
              ...(presentation.href ? { href: presentation.href } : {}),
              id: step.id,
              status: labels[presentation.status],
              statusTone: tones[presentation.status],
              title: step.title,
            };
          }),
        },
      ];
    }),
    period: `${formatProgramDate(participantProgram.program.startsOn, participantProgram.program.timezone)}–${formatProgramDate(participantProgram.program.endsOn, participantProgram.program.timezone)} · ${programTimezoneLabel(participantProgram.program.timezone)}`,
    progress: participantProgram.score.progressPercentage,
    title: participantProgram.program.title,
  };
  return <ProgramActivityRenderer audience="participant" model={model} />;
}

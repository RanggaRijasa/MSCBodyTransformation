import type { AppError } from "@/domain/errors/app-error";
import type { EnrollmentProjection, PublicProgram } from "@/domain/programs/program";
import type {
  ParticipantProgram,
  PublicCoach,
  PublicLeaderboardEntry,
  PublicWinner,
  PublicWinnerPoster,
} from "@/domain/participant/participant-program";
import type { Result } from "@/domain/result";

export type PublicProgramRepository = Readonly<{
  get(programId: string): Promise<Result<PublicProgram | null, AppError>>;
  list(): Promise<Result<readonly PublicProgram[], AppError>>;
}>;

export type EnrollmentProjectionRepository = Readonly<{
  listMine(): Promise<Result<readonly EnrollmentProjection[], AppError>>;
}>;

export type ParticipantExperienceRepository = Readonly<{
  listCoaches(): Promise<Result<readonly PublicCoach[], AppError>>;
  listMyPrograms(): Promise<Result<readonly ParticipantProgram[], AppError>>;
  listLeaderboard(
    programId: string,
    limit?: number,
    offset?: number,
  ): Promise<Result<readonly PublicLeaderboardEntry[], AppError>>;
  listWinnerPosters(): Promise<Result<readonly PublicWinnerPoster[], AppError>>;
  listWinners(programId: string): Promise<Result<readonly PublicWinner[], AppError>>;
}>;

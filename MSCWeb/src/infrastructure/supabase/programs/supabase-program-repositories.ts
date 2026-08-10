import "server-only";

import { AppError } from "@/domain/errors/app-error";
import { parsePublicProgram } from "@/domain/programs/program-contract";
import type { EnrollmentProjection, PublicProgram } from "@/domain/programs/program";
import type {
  EnrollmentProjectionRepository,
  PublicProgramRepository,
} from "@/domain/repositories/program-repository";
import { failure, success } from "@/domain/result";
import { createSupabaseServerClient } from "@/infrastructure/supabase/client/server";

function publicCoverPath(value: unknown): string | null {
  if (value === null) return null;
  if (
    typeof value !== "string" ||
    value.length === 0 ||
    value.length > 512 ||
    value.includes("..") ||
    value.includes("://") ||
    value.startsWith("/")
  ) {
    return null;
  }
  return value;
}

function rawRecord(value: unknown): Record<string, unknown> | null {
  return value !== null && typeof value === "object" && !Array.isArray(value)
    ? (value as Record<string, unknown>)
    : null;
}

async function mapPrograms(
  values: unknown,
  client: Awaited<ReturnType<typeof createSupabaseServerClient>>,
) {
  if (!Array.isArray(values)) {
    return failure(new AppError("validation_failed", "Respons katalog program tidak valid."));
  }
  const programs: PublicProgram[] = [];
  for (const value of values) {
    const parsed = parsePublicProgram(value);
    if (!parsed.isSuccess) return parsed;
    const path = publicCoverPath(rawRecord(value)?.cover_path);
    const coverImageUrl = path
      ? client.storage.from("public-media").getPublicUrl(path).data.publicUrl
      : null;
    programs.push({
      ...parsed.value,
      coverImageUrl,
      days: parsed.value.days.map((day) => ({
        ...day,
        steps: day.steps.map((step) => ({
          ...step,
          mediaUrl: step.mediaPath
            ? client.storage.from("public-media").getPublicUrl(step.mediaPath).data.publicUrl
            : null,
          questions: step.questions.map((question) => ({
            ...question,
            options: question.options.map((option) => ({
              ...option,
              mediaUrl: option.mediaPath
                ? client.storage.from("public-media").getPublicUrl(option.mediaPath).data.publicUrl
                : null,
            })),
          })),
        })),
      })),
    });
  }
  return success(programs);
}

async function loadPublicPrograms(programId?: string) {
  try {
    const client = await createSupabaseServerClient();
    const { data, error } = await client.rpc("list_public_programs", {
      result_limit: programId ? 1 : 50,
      result_offset: 0,
      target_program_id: programId ?? null,
    });
    if (error) {
      return failure(
        new AppError("unknown", "Katalog program belum dapat dimuat.", { cause: error }),
      );
    }
    return mapPrograms(data, client);
  } catch (error) {
    return failure(
      error instanceof AppError
        ? error
        : new AppError("unknown", "Katalog program belum dapat dimuat.", { cause: error }),
    );
  }
}

export const supabasePublicProgramRepository: PublicProgramRepository = {
  async get(programId) {
    const result = await loadPublicPrograms(programId);
    return result.isSuccess ? success(result.value[0] ?? null) : result;
  },
  list: () => loadPublicPrograms(),
};

export const supabaseEnrollmentProjectionRepository: EnrollmentProjectionRepository = {
  async listMine() {
    try {
      const client = await createSupabaseServerClient();
      const { data, error } = await client
        .from("program_enrollments")
        .select("id,program_id,status")
        .in("status", ["active", "completed"]);
      if (error || !Array.isArray(data)) {
        return failure(
          new AppError("unknown", "Program yang diikuti belum dapat dimuat.", { cause: error }),
        );
      }
      const projections: EnrollmentProjection[] = [];
      for (const row of data) {
        if (
          typeof row.id !== "string" ||
          typeof row.program_id !== "string" ||
          (row.status !== "active" && row.status !== "completed")
        ) {
          return failure(new AppError("validation_failed", "Data enrollment tidak valid."));
        }
        projections.push({ enrollmentId: row.id, programId: row.program_id, status: row.status });
      }
      return success(projections);
    } catch (error) {
      return failure(
        error instanceof AppError
          ? error
          : new AppError("unknown", "Program yang diikuti belum dapat dimuat.", { cause: error }),
      );
    }
  },
};

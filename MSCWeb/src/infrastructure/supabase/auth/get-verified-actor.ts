import "server-only";

import { AppError } from "@/domain/errors/app-error";
import { failure, success, type Result } from "@/domain/result";
import { createSupabaseServerClient } from "@/infrastructure/supabase/client/server";

export type VerifiedActor = Readonly<{
  email: string;
  userId: string;
}>;

export type VerifiedSupabaseContext = Readonly<{
  actor: VerifiedActor;
  supabase: Awaited<ReturnType<typeof createSupabaseServerClient>>;
}>;

export async function getVerifiedSupabaseContext(): Promise<
  Result<VerifiedSupabaseContext, AppError>
> {
  try {
    const supabase = await createSupabaseServerClient();
    const { data, error } = await supabase.auth.getClaims();
    const subject = data?.claims.sub;
    const email = data?.claims.email;

    if (
      error ||
      typeof subject !== "string" ||
      subject.length === 0 ||
      typeof email !== "string" ||
      email.length === 0
    ) {
      return failure(new AppError("unauthorized", "Sesi perlu diperbarui."));
    }

    return success({ actor: { email, userId: subject }, supabase });
  } catch (error) {
    if (error instanceof AppError) {
      return failure(error);
    }

    return failure(new AppError("unknown", "Sesi belum dapat diverifikasi.", { cause: error }));
  }
}

export async function getVerifiedActor(): Promise<Result<VerifiedActor, AppError>> {
  const context = await getVerifiedSupabaseContext();
  return context.isSuccess ? success(context.value.actor) : failure(context.error);
}

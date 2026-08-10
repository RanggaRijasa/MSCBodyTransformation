import "server-only";

import { AppError } from "@/domain/errors/app-error";
import { buildCoachQrUrl } from "@/domain/media/qr-payload";
import { failure, success, type Result } from "@/domain/result";
import { getVerifiedSupabaseContext } from "@/infrastructure/supabase/auth/get-verified-actor";
import { renderQrSvg } from "@/infrastructure/qr/qr-svg-renderer";
import { getSiteOrigin } from "@/shared/config/site-url";

type CoachQrRow = Readonly<{
  coach_is_approved: boolean;
  coach_qr_identifier: string | null;
  role: string;
}>;

export async function loadCoachQrSvgOperation(): Promise<Result<string, AppError>> {
  const context = await getVerifiedSupabaseContext();
  if (!context.isSuccess) return context;
  const { data, error } = await context.value.supabase
    .from("profiles")
    .select("role,coach_is_approved,coach_qr_identifier")
    .eq("user_id", context.value.actor.userId)
    .single<CoachQrRow>();
  if (error || !data) {
    return failure(new AppError("unknown", "QR Coach belum dapat dimuat.", { cause: error }));
  }
  if (data.role !== "coach" || !data.coach_is_approved || !data.coach_qr_identifier) {
    return failure(new AppError("forbidden", "QR Coach belum tersedia untuk akun ini."));
  }
  const url = buildCoachQrUrl(data.coach_qr_identifier, getSiteOrigin());
  if (!url.isSuccess) return url;
  return success(renderQrSvg(url.value.toString()));
}

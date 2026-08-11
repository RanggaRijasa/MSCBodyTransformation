import "server-only";

import { createClient } from "@supabase/supabase-js";

import { AppError } from "@/domain/errors/app-error";
import { readPublicEnvironment } from "@/shared/config/environment";

export function createSupabaseServiceClient() {
  const environment = readPublicEnvironment();
  if (!environment.isSuccess) throw environment.error;
  const hostname = new URL(environment.value.supabaseUrl).hostname;
  const isLocal = hostname === "127.0.0.1" || hostname === "localhost";
  const secret =
    process.env.SUPABASE_SECRET_KEY ??
    (isLocal ? process.env.SUPABASE_TEST_SERVICE_ROLE_KEY : undefined);
  if (!secret) {
    throw new AppError("configuration_invalid", "Layanan penyimpanan privat belum tersedia.");
  }
  return createClient(environment.value.supabaseUrl, secret, {
    auth: { autoRefreshToken: false, persistSession: false },
  });
}

import { AppError } from "@/domain/errors/app-error";
import { failure, success, type Result } from "@/domain/result";

export type PublicEnvironment = Readonly<{
  supabaseUrl: string;
  supabasePublishableKey: string;
}>;

type PublicEnvironmentInput = Readonly<{
  supabaseUrl?: string | undefined;
  supabasePublishableKey?: string | undefined;
}>;

export function parsePublicEnvironment(
  input: PublicEnvironmentInput,
): Result<PublicEnvironment, AppError> {
  const supabaseUrl = input.supabaseUrl?.trim();
  const supabasePublishableKey = input.supabasePublishableKey?.trim();

  if (!supabaseUrl || !supabasePublishableKey) {
    return failure(new AppError("configuration_invalid", "Konfigurasi layanan belum tersedia."));
  }

  try {
    const parsedUrl = new URL(supabaseUrl);
    if (!new Set(["http:", "https:"]).has(parsedUrl.protocol)) {
      throw new TypeError("Unsupported protocol");
    }
  } catch (error) {
    return failure(
      new AppError("configuration_invalid", "Alamat layanan tidak valid.", { cause: error }),
    );
  }

  return success({ supabaseUrl, supabasePublishableKey });
}

export function readPublicEnvironment(): Result<PublicEnvironment, AppError> {
  return parsePublicEnvironment({
    supabaseUrl: process.env.NEXT_PUBLIC_SUPABASE_URL,
    supabasePublishableKey: process.env.NEXT_PUBLIC_SUPABASE_PUBLISHABLE_KEY,
  });
}

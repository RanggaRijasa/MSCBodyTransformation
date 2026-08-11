import "server-only";

import { AppError } from "@/domain/errors/app-error";

export type AuthServerEnvironment = Readonly<{
  cookieSecret: string;
  environmentName: string;
}>;

export function readAuthServerEnvironment(): AuthServerEnvironment {
  const cookieSecret = process.env.AUTH_FLOW_COOKIE_SECRET?.trim();
  if (!cookieSecret || cookieSecret.length < 32) {
    throw new AppError("configuration_invalid", "Konfigurasi keamanan autentikasi belum tersedia.");
  }
  return {
    cookieSecret,
    environmentName: process.env.APP_ENVIRONMENT?.trim() || process.env.NODE_ENV || "development",
  };
}

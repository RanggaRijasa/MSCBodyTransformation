import { AppError } from "@/domain/errors/app-error";
import { failure, success, type Result } from "@/domain/result";

declare const coachQrPayloadBrand: unique symbol;
export type OpaqueCoachQrPayload = string & { readonly [coachQrPayloadBrand]: true };

const qrPathPrefix = "/gabung/coach/";
const tokenPattern = /^[A-Za-z0-9_-]{4,128}$/;

export function parseCoachQrUrl(
  rawValue: string,
  allowedOrigins: readonly string[],
): Result<OpaqueCoachQrPayload, AppError> {
  try {
    const url = new URL(rawValue);
    if (
      url.protocol !== "https:" &&
      !(url.protocol === "http:" && ["localhost", "127.0.0.1"].includes(url.hostname))
    ) {
      throw new TypeError("Protokol QR tidak aman");
    }
    if (
      !allowedOrigins.includes(url.origin) ||
      url.search ||
      url.hash ||
      !url.pathname.startsWith(qrPathPrefix)
    ) {
      throw new TypeError("Origin atau path QR tidak valid");
    }
    const token = url.pathname.slice(qrPathPrefix.length);
    if (!tokenPattern.test(token) || token.includes("/"))
      throw new TypeError("Token QR tidak valid");
    return success(token as OpaqueCoachQrPayload);
  } catch (error) {
    return failure(
      new AppError("validation_failed", "QR Coach tidak valid untuk MSC.", { cause: error }),
    );
  }
}

export function buildCoachQrUrl(token: string, origin: URL): Result<URL, AppError> {
  if (!tokenPattern.test(token)) {
    return failure(new AppError("validation_failed", "Identifier QR Coach tidak valid."));
  }
  if (
    origin.protocol !== "https:" &&
    !(origin.protocol === "http:" && ["localhost", "127.0.0.1"].includes(origin.hostname))
  ) {
    return failure(new AppError("configuration_invalid", "Origin QR harus menggunakan HTTPS."));
  }
  return success(new URL(`${qrPathPrefix}${token}`, origin));
}

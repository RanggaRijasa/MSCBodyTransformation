export type AppErrorCode =
  | "configuration_invalid"
  | "offline"
  | "timeout"
  | "unauthorized"
  | "forbidden"
  | "conflict"
  | "validation_failed"
  | "unknown";

export class AppError extends Error {
  readonly code: AppErrorCode;
  override readonly cause?: unknown;

  constructor(code: AppErrorCode, message: string, options?: { cause?: unknown }) {
    super(message);
    this.name = "AppError";
    this.code = code;
    this.cause = options?.cause;
  }
}

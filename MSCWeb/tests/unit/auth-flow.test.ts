import { describe, expect, it } from "vitest";

import {
  AUTH_FLOW_TTL_SECONDS,
  createAuthFlowAttempt,
  createPendingProgramIntent,
  isPendingProgramIntentValid,
  safeReturnTo,
  validateAuthFlowAttempt,
} from "@/features/auth/model/auth-flow";

describe("auth flow security", () => {
  it.each([
    "https://evil.example",
    "//evil.example/path",
    "/\\evil.example",
    "/ketentuan",
    "javascript:alert(1)",
  ])("menolak return-to di luar allowlist: %s", (value) => {
    expect(safeReturnTo(value)).toBe("/hari-ini");
  });

  it("mempertahankan path, query, dan fragmen internal yang diizinkan", () => {
    expect(safeReturnTo("/program/abc?tab=ringkasan#hari-2")).toBe(
      "/program/abc?tab=ringkasan#hari-2",
    );
  });

  it("memvalidasi state, environment, dan TTL sebagai satu transaksi", () => {
    const attempt = createAuthFlowAttempt({
      environment: "local",
      mode: "login",
      now: 100,
      returnTo: "/profil",
      state: "state-aman",
    });
    expect(
      validateAuthFlowAttempt(attempt, {
        environment: "local",
        now: 100 + AUTH_FLOW_TTL_SECONDS - 1,
        state: "state-aman",
      }),
    ).toBe(true);
    expect(
      validateAuthFlowAttempt(attempt, {
        environment: "production",
        now: 101,
        state: "state-aman",
      }),
    ).toBe(false);
    expect(
      validateAuthFlowAttempt(attempt, {
        environment: "local",
        now: 101,
        state: "state-palsu",
      }),
    ).toBe(false);
    expect(
      validateAuthFlowAttempt(attempt, {
        environment: "local",
        now: 100 + AUTH_FLOW_TTL_SECONDS,
        state: "state-aman",
      }),
    ).toBe(false);
  });

  it("intent program hanya menerima UUID publik dan tidak memiliki ruang QR", () => {
    const intent = createPendingProgramIntent({
      environment: "local",
      now: 10,
      programId: "8acb9e0e-42ee-4c98-a7a5-10786e286657",
    });
    expect(intent).not.toBeNull();
    expect(JSON.stringify(intent)).not.toMatch(/qr|coach/i);
    expect(
      createPendingProgramIntent({ environment: "local", now: 10, programId: "raw-coach-qr" }),
    ).toBeNull();
  });

  it("intent program kedaluwarsa dan terikat environment", () => {
    const intent = createPendingProgramIntent({
      environment: "local",
      now: 10,
      programId: "8acb9e0e-42ee-4c98-a7a5-10786e286657",
    });
    expect(intent && isPendingProgramIntentValid(intent, { environment: "local", now: 11 })).toBe(
      true,
    );
    expect(
      intent && isPendingProgramIntentValid(intent, { environment: "production", now: 11 }),
    ).toBe(false);
    expect(
      intent &&
        isPendingProgramIntentValid(intent, { environment: "local", now: intent.expiresAt }),
    ).toBe(false);
  });
});

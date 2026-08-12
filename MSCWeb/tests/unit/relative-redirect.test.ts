import { describe, expect, it } from "vitest";

import { relativeRedirect } from "@/shared/security/relative-redirect";

describe("relativeRedirect", () => {
  it("menghasilkan Location internal relatif tanpa authority browser", () => {
    const response = relativeRedirect("/masuk?returnTo=%2Fprogram%2Fabc", 303);

    expect(response.status).toBe(303);
    expect(response.headers.get("location")).toBe("/masuk?returnTo=%2Fprogram%2Fabc");
  });

  it.each([
    "https://evil.invalid/masuk",
    "//evil.invalid/masuk",
    "/\\evil.invalid/masuk",
    "/\\\\evil.invalid/masuk",
    "masuk",
  ])("menolak tujuan non-relatif %s", (location) => {
    expect(() => relativeRedirect(location)).toThrow(/path relatif yang aman/);
  });

  it("mempertahankan query dan hash pada path relatif yang aman", () => {
    const location = "/masuk?returnTo=%2Fprogram%2Fabc#lanjut";

    expect(relativeRedirect(location).headers.get("location")).toBe(location);
  });
});

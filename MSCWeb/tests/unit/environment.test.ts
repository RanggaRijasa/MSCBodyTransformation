import { describe, expect, it } from "vitest";

import { parsePublicEnvironment } from "@/shared/config/environment";

describe("parsePublicEnvironment", () => {
  it("menerima URL dan publishable key tanpa secret server", () => {
    const result = parsePublicEnvironment({
      supabaseUrl: "http://127.0.0.1:54321",
      supabasePublishableKey: "local-publishable-key",
    });

    expect(result).toEqual({
      isSuccess: true,
      value: {
        supabaseUrl: "http://127.0.0.1:54321",
        supabasePublishableKey: "local-publishable-key",
      },
    });
  });

  it("gagal tertutup ketika konfigurasi tidak tersedia", () => {
    const result = parsePublicEnvironment({});

    expect(result.isSuccess).toBe(false);
    if (!result.isSuccess) {
      expect(result.error.code).toBe("configuration_invalid");
    }
  });

  it("menolak protokol selain HTTP atau HTTPS", () => {
    const result = parsePublicEnvironment({
      supabaseUrl: "file:///tmp/database",
      supabasePublishableKey: "local-publishable-key",
    });

    expect(result.isSuccess).toBe(false);
  });
});

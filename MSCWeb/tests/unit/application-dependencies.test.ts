import { describe, expect, it } from "vitest";

import { makeApplicationDependencies } from "@/app/composition/application-dependencies";

describe("makeApplicationDependencies", () => {
  it("memasang repository deterministic untuk local demo", async () => {
    const dependencies = makeApplicationDependencies("local-demo");

    await expect(dependencies.serviceHealthRepository.checkAvailability()).resolves.toEqual({
      isSuccess: true,
      value: "available",
    });
  });

  it("gagal tertutup ketika composition Supabase belum dikonfigurasi", async () => {
    const dependencies = makeApplicationDependencies("supabase");

    const result = await dependencies.serviceHealthRepository.checkAvailability();
    expect(result.isSuccess).toBe(false);
    if (!result.isSuccess) {
      expect(result.error.code).toBe("configuration_invalid");
    }
  });
});

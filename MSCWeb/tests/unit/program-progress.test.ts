import { describe, expect, it } from "vitest";

import { calculateCompletionPercentage } from "@/domain/services/program-progress";

describe("calculateCompletionPercentage", () => {
  it("menghitung persentase aktivitas secara deterministik", () => {
    const result = calculateCompletionPercentage(3, 4);

    expect(result).toEqual({ isSuccess: true, value: 75 });
  });

  it("mengembalikan nol ketika program tidak mempunyai aktivitas", () => {
    const result = calculateCompletionPercentage(0, 0);

    expect(result).toEqual({ isSuccess: true, value: 0 });
  });

  it("menolak jumlah selesai yang melebihi requirement", () => {
    const result = calculateCompletionPercentage(5, 4);

    expect(result.isSuccess).toBe(false);
    if (!result.isSuccess) {
      expect(result.error.code).toBe("validation_failed");
    }
  });
});

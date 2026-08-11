import { describe, expect, it } from "vitest";

import {
  createProgramDateFormatter,
  formatCurrencyIDR,
  formatNumber,
  formatWeightKilograms,
} from "@/shared/formatting/indonesian-formatters";

describe("formatter Bahasa Indonesia", () => {
  it("tidak mengikuti locale browser berbahasa Inggris", () => {
    expect(formatNumber.format(12_350)).toBe("12.350");
    expect(formatCurrencyIDR.format(149_000)).toContain("149.000");
    expect(formatWeightKilograms.format(78.5)).toContain("78,5");
  });

  it("mempertahankan timezone program", () => {
    const formatter = createProgramDateFormatter("Asia/Makassar");
    const result = formatter.format(new Date("2026-08-10T16:30:00Z"));

    expect(result).toContain("11 Agustus 2026");
  });
});

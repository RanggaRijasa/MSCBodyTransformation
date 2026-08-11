import { NextRequest } from "next/server";
import { describe, expect, it } from "vitest";

import { hasTrustedMutationOrigin } from "@/shared/security/mutation-origin";

function mutationRequest({
  headers = {},
  url = "http://localhost:3000/api/example",
}: {
  headers?: Record<string, string>;
  url?: string;
} = {}) {
  return new NextRequest(url, { headers, method: "POST" });
}

describe("mutation origin", () => {
  it("memakai host request efektif ketika Next menormalkan hostname development", () => {
    const request = mutationRequest({
      headers: {
        host: "127.0.0.1:3000",
        origin: "http://127.0.0.1:3000",
        "sec-fetch-site": "same-origin",
      },
    });

    expect(hasTrustedMutationOrigin(request)).toBe(true);
  });

  it("menghormati host dan protokol yang diteruskan reverse proxy", () => {
    const request = mutationRequest({
      headers: {
        host: "internal:3000",
        origin: "https://app.example.com",
        "sec-fetch-site": "same-origin",
        "x-forwarded-host": "app.example.com",
        "x-forwarded-proto": "https",
      },
    });

    expect(hasTrustedMutationOrigin(request)).toBe(true);
  });

  it("menolak origin lintas situs dan host yang tidak cocok", () => {
    expect(
      hasTrustedMutationOrigin(
        mutationRequest({
          headers: {
            host: "app.example.com",
            origin: "https://evil.example",
            "sec-fetch-site": "cross-site",
            "x-forwarded-proto": "https",
          },
        }),
      ),
    ).toBe(false);

    expect(
      hasTrustedMutationOrigin(
        mutationRequest({
          headers: {
            host: "app.example.com",
            origin: "https://other.example.com",
            "sec-fetch-site": "same-site",
            "x-forwarded-proto": "https",
          },
        }),
      ),
    ).toBe(false);
  });

  it("menolak origin atau host efektif yang malformed", () => {
    expect(
      hasTrustedMutationOrigin(
        mutationRequest({
          headers: {
            host: "app.example.com/path",
            origin: "not a URL",
            "sec-fetch-site": "same-origin",
          },
        }),
      ),
    ).toBe(false);
  });

  it("hanya menerima request tanpa Origin bila browser menyatakan same-origin", () => {
    expect(
      hasTrustedMutationOrigin(
        mutationRequest({
          headers: { host: "localhost:3000", "sec-fetch-site": "same-origin" },
        }),
      ),
    ).toBe(true);
    expect(
      hasTrustedMutationOrigin(
        mutationRequest({
          headers: { host: "localhost:3000", "sec-fetch-site": "same-site" },
        }),
      ),
    ).toBe(false);
  });
});

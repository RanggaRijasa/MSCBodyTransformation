import { expect, test } from "@playwright/test";

test("media routes memakai camera policy dan Guest gagal tertutup", async ({ page, request }) => {
  const landing = await request.get("/");
  expect(landing.headers()["permissions-policy"]).toBe(
    "camera=(self), microphone=(), geolocation=(), payment=(), usb=()",
  );

  const qrImage = await request.get("/api/coach/qr-image");
  expect(qrImage.status()).toBe(401);
  expect(qrImage.headers()["cache-control"]).toContain("no-store");
  const payload = (await qrImage.json()) as Record<string, unknown>;
  expect(payload).toEqual({ code: "qr_unavailable" });
  expect(JSON.stringify(payload)).not.toMatch(/identifier|token|coach_qr/i);

  await page.goto("/coach-area/qr");
  await expect(page).toHaveURL(/\/masuk\?returnTo=%2Fcoach-area%2Fqr/);
  await expect(page.getByRole("textbox", { name: /kode coach/i })).toHaveCount(0);
});

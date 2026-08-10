import assert from "node:assert/strict";

const apiURL = requireEnvironment("API_URL");

assert.ok(
  ["127.0.0.1", "localhost", "::1"].includes(new URL(apiURL).hostname),
  "Legal endpoint test must target local Supabase",
);

function requireEnvironment(name) {
  const value = process.env[name];
  if (!value) throw new Error(`Missing required environment variable: ${name}`);
  return value;
}

for (const [slug, title, expectedText] of [
  [
    "privacy",
    "Kebijakan Privasi MSC Body Transformation",
    "Aplikasi tidak menggunakan data untuk pelacakan",
  ],
  [
    "terms",
    "Ketentuan Penggunaan MSC Body Transformation",
    "Tidak tersedia pengembalian dana sukarela",
  ],
]) {
  const response = await fetch(`${apiURL}/functions/v1/legal/${slug}`);
  const html = await response.text();
  assert.equal(response.status, 200, `${slug} must be public`);
  assert.match(
    response.headers.get("content-type") ?? "",
    /^text\/html; charset=utf-8$/,
  );
  assert.equal(response.headers.get("content-language"), "id-ID");
  assert.equal(response.headers.get("x-frame-options"), "DENY");
  assert.match(html, new RegExp(title));
  assert.match(html, new RegExp(expectedText));

  const head = await fetch(`${apiURL}/functions/v1/legal/${slug}`, {
    method: "HEAD",
  });
  assert.equal(head.status, 200, `${slug} HEAD must work`);
  assert.equal(await head.text(), "", `${slug} HEAD must not include a body`);
}

const missing = await fetch(`${apiURL}/functions/v1/legal/not-found`);
assert.equal(missing.status, 404);

const mutation = await fetch(`${apiURL}/functions/v1/legal/privacy`, {
  method: "POST",
});
assert.equal(mutation.status, 405);
assert.equal(mutation.headers.get("allow"), "GET, HEAD");

console.log("Phase 13 public legal endpoint checks passed: 16");

export async function isAuthorizedJobRequest(
  request: Request,
  environmentName: string,
): Promise<boolean> {
  const expected = Deno.env.get(environmentName)?.trim();
  const authorization = request.headers.get("authorization") ?? "";
  const supplied = authorization.startsWith("Bearer ")
    ? authorization.slice("Bearer ".length)
    : "";
  if (!expected || !supplied) return false;

  const [expectedDigest, suppliedDigest] = await Promise.all([
    sha256(expected),
    sha256(supplied),
  ]);
  if (expectedDigest.length !== suppliedDigest.length) return false;

  let difference = 0;
  for (let index = 0; index < expectedDigest.length; index += 1) {
    difference |= expectedDigest[index]! ^ suppliedDigest[index]!;
  }
  return difference === 0;
}

async function sha256(value: string): Promise<Uint8Array> {
  const bytes = new TextEncoder().encode(value);
  return new Uint8Array(await crypto.subtle.digest("SHA-256", bytes));
}
